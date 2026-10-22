# oci/block-volume

One block volume with an optional attachment to an instance (paravirtualized, encrypted in
transit) and an optional Oracle backup policy.

- Upstream: none; resources written on provider `oracle/oci` (ADR 0002 exception, below).
- Validation level: L1, 2026-10-22 on the Linux validation host (pre-commit all hooks
  passed; `terraform test` 8 passed; terraform 1.16.5, trivy 0.75.0, checkov 3.3.29).
  L2 not run, so releases stay at v0.x (ADR 0003).
- Example: [examples/oci/storage](../../../examples/oci/storage).

## Why no upstream module

ADR 0002 allows direct resources when no maintained upstream module covers the need.

- OCI Landing Zones `terraform-oci-modules-workloads` v0.2.9 (`cis-compute-storage`) has
  block volumes, but inside the compute module: the caller must pass a second provider
  (`oci.block_volumes_replication_region`) even without replication, and attachments refer
  to instances by module keys. Using it next to `oci/compute` means two compute stacks.
- `oracle-terraform-modules/terraform-oci-tdf-block-storage`: last tag v0.1.5, last push
  2021-03-23, not maintained.

Same decision as `oci/compute` (repository owner, 2026-10-21). Revisit if upstream splits
block storage into its own module.

## Defaults

| Setting | Default | Control |
|---|---|---|
| Size and performance | 50 GB, 10 VPUs/GB (balanced) | B-12, Always Free |
| Encryption at rest | Oracle-managed key; `kms_key_id` for a Vault key | B-03, checkov `CKV_OCI_3` skipped inline |
| Attachment | none; paravirtualized when `instance_id` is set | |
| In-transit encryption | on for paravirtualized attachments | B-04 |
| Backup policy | none | B-09 is set per blueprint; checkov `CKV_OCI_2` skipped inline |
| Tags | `var.tags` plus `managed-by=terraform`, `iac-module=oci/block-volume` | ADR 0004 |

`CKV_OCI_2` reads the deprecated `backup_policy_id` argument of `oci_core_volume`; this
module assigns policies with `oci_core_volume_backup_policy_assignment`, which the check
does not see.

Names (ADR 0004, `name` = prefix from `multi/naming`): `<name>-bv[-<qualifier>][-NN]`; the
attachment adds `-att`.

OCI Always Free (checked 2026-10-22 in the Oracle documentation): 200 GB of boot and block
volume storage in total and 5 volume backups in total, home region only.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | prefix from `multi/naming` (`<org>-<workload>-<env>-<region>`) |
| `qualifier` | string | `null` | role after the type, for example `data` |
| `volume_number` | number | `null` | appends `-NN` (1 to 99) |
| `compartment_id` | string | required | compartment OCID |
| `availability_domain` | number | `1` | AD number (1 to 3); same as the instance |
| `size_in_gbs` | number | `50` | 50 to 32768 |
| `vpus_per_gb` | number | `10` | multiple of 10, 0 to 120 |
| `kms_key_id` | string | `null` | Vault key, for example from `oci/vault` (`key_ids`; grant `blockstorage`) |
| `backup_policy` | string | `null` | `bronze`, `silver`, `gold` or null |
| `instance_id` | string | `null` | instance OCID to attach to |
| `attachment_type` | string | `paravirtualized` | or `iscsi` |
| `device` | string | `null` | `/dev/oracleoci/oraclevdb` style path |
| `read_only` | bool | `false` | read-only attachment |
| `encrypt_in_transit` | bool | `true` | paravirtualized only |
| `tags` | map(string) | `{}` | freeform tags |
| `defined_tags` | map(string) | `null` | defined tags |

## Outputs

`volume_id`, `name`, `attachment_id`, `device` (null when detached).

## Known gaps

- No deletion protection: OCI block volumes have no such flag and `prevent_destroy` cannot
  be set from a variable (B-13). Consumers that need it add a lifecycle block in their root
  module or keep the volume in its own state.
- No cross-region replicas, volume groups, custom backup policies, auto-tune or creation
  from a backup or clone yet.
- The availability domain is not checked against the instance; a mismatch fails at apply.
- In-transit encryption needs the instance launched with it (`oci/compute` does by default).
- The module attaches the volume only; formatting and mounting belong to cloud-init or
  configuration management.

## Tests

`tests/defaults.tftest.hcl`, mocked provider: secure defaults, attached volume with
qualifier, number, AD and bronze backup, iSCSI without paravirtualized encryption, and
rejection of a small volume, bad VPUs, a bad qualifier, an unknown backup policy and an
unknown attachment type.

```bash
make test DIR=modules/oci/block-volume
```
