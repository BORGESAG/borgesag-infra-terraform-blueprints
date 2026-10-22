# oci/vault

One OCI Vault (or an existing one) with master encryption keys and per-key grant policies,
for customer-managed encryption of block volumes, buckets and other services.

- Upstream: none; resources written on provider `oracle/oci` (ADR 0002 exception, below).
- Validation level: L1, 2026-10-22 on the Linux validation host (pre-commit all hooks
  passed; `terraform test` 7 passed; terraform 1.16.5, trivy 0.75.0, checkov 3.3.29).
  L2 not run, so releases stay at v0.x (ADR 0003).
- Example: [examples/oci/vault](../../../examples/oci/vault).

## Why no upstream module

The OCI Landing Zones security module `vaults` (v0.2.3, 2025-11-07, the latest release when
checked on 2026-10-22) was tried as a wrapper and dropped:

- it lists the default `oci` provider in `configuration_aliases` (with `oci.home`), so every
  caller of this module, and of any blueprint built on it, would have to pass
  `providers = { oci = oci }` explicitly (confirmed with `terraform validate` on the
  example);
- its grant statements name the compartment (`in compartment <name>`), so they break when the
  compartment is renamed, and its policy names (`<key name>-policy`) are outside ADR 0004;
- its grants for existing keys read attributes the input type does not define.

`oracle-terraform-modules` has no vault module. Four provider resources cover the need: vault,
key, key version and the grant policy. Grant statements use `in compartment id <OCID>`, like
`oci/iam`. The policy is an IAM change: point the provider at the home region.

## Defaults

| Setting | Default | Control |
|---|---|---|
| Vault | created as `<name>-kv`, type `DEFAULT` (shared partition); `vault_id` uses an existing one | B-03 |
| Keys | none; `HSM`, AES, 32 bytes (AES-256) | B-03 |
| HSM key versions | at most 20 from this module (`hsm_key_version_limit`) | B-12, OCI Always Free |
| Grants | one policy `<name>-pol-key-<key>` per key with grantees, limited to that key | B-01 |
| Rotation | manual: add a label to `versions` (one new key version each) | |
| Tags | `var.tags` plus `managed-by=terraform`, `iac-module=oci/vault` | ADR 0004 |

Grant statements:

- service: `Allow service <s> to use keys in compartment id <c> where target.key.id = '<key>'`,
  for example `objectstorage-sa-saopaulo-1` (buckets) or `blockstorage` (volumes);
- group and dynamic group: `... to use key-delegate ...` (encrypt and decrypt through the key).

Pass `key_ids` to the `kms_key_id` input of `oci/block-volume` or `oci/object-storage`; the
service grant must exist first (same apply, or apply this module first).

OCI Always Free (Oracle docs "Always Free Resources", checked 2026-10-22): every software key
version is free, 20 HSM key versions per tenancy and 150 secrets, across any number of
`DEFAULT` vaults; virtual private vaults are not included. Rotating an HSM key spends one
version.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | prefix from `multi/naming` (`<org>-<workload>-<env>-<region>`) |
| `compartment_id` | string | required | compartment for vault, keys and policies |
| `vault_id` | string | `null` | existing vault; null creates `<name>-kv` |
| `keys` | map(object) | `{}` | `algorithm` (`AES`/`RSA`/`ECDSA`), `length` (bytes), `protection_mode` (`HSM`/`SOFTWARE`), `versions`, `service_grantees`, `group_grantees`, `dynamic_group_grantees` |
| `hsm_key_version_limit` | number | `20` | null disables the check |
| `tags` | map(string) | `{}` | freeform tags |
| `defined_tags` | map(string) | `null` | defined tags |

Key lengths: AES 16, 24 or 32; RSA 256, 384 or 512; ECDSA 32, 48 or 66 (curve P-256, P-384 or
P-521 is set from the length).

## Outputs

`vault_id`, `vault_name` (null for an existing vault), `management_endpoint`,
`crypto_endpoint`, `key_ids`, `key_version_ids` (keyed `<key>.<label>`), `grant_policy_ids`.

## Deleting

`terraform destroy` schedules deletion: OCI keeps the vault and its keys pending deletion for
30 days by default (7 to 30, Oracle docs "Deleting a Vault"); keys are deleted with their
vault. Re-encrypt buckets and volumes with another key before destroying. A key removed from
`keys` is scheduled for deletion the same way; keys use `create_before_destroy` so a
replacement exists before the old key goes.

## Known gaps

- No secrets, no virtual private vault (not in OCI Always Free), no replication and no
  automatic rotation (the Landing Zones module enables it only for virtual private vaults).
- The HSM check counts only this module's keys; other HSM keys in the tenancy share the 20.

## Tests

`tests/defaults.tftest.hcl`, mocked provider: new vault with an HSM key and a grant policy
for two services and a dynamic group; existing vault with a software key, one extra version
and an ECDSA key; the HSM limit rejected and switched off; and rejection of a bad key shape, a
bad grantee and a bad vault OCID.

```bash
make test DIR=modules/oci/vault
```
