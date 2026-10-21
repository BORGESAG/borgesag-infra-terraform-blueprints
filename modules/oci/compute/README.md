# oci/compute

One compute instance with a private VNIC, legacy metadata endpoints off, in-transit volume
encryption on and an optional Oracle backup policy.

- Upstream: none; resources written on provider `oracle/oci` (ADR 0002 exception, below).
- Validation level: L1, 2026-10-21 on the Linux validation host (pre-commit all hooks
  passed; `terraform test` 6 passed; terraform 1.16.5, trivy 0.75.0, checkov 3.3.29).
  L2 not run, so releases stay at v0.x (ADR 0003).
- Example: [examples/oci/compute](../../../examples/oci/compute).

## Why no upstream module

ADR 0002 allows direct resources when no maintained upstream module covers the need.

- `oracle-terraform-modules/terraform-oci-compute-instance`: last release v2.4.1 (2022-11-29),
  not maintained.
- OCI Landing Zones `terraform-oci-modules-workloads` v0.2.9 (`cis-compute-storage`):
  maintained, but it always attaches an Oracle backup policy (gold, silver or bronze) to the
  boot volume. Bronze alone keeps 12 monthly backups plus a yearly one, and OCI Always Free
  includes 5 volume backups in total, so a lab instance goes past the free allowance in
  about five months (B-12). Decision approved by the repository owner on 2026-10-21.

Revisit when the upstream module accepts "no backup policy".

## Defaults

| Setting | Default | Control |
|---|---|---|
| Public IP | off | B-05 |
| Legacy IMDS (v1) endpoints | disabled | checkov `CKV_OCI_5` |
| In-transit volume encryption | on | B-04, checkov `CKV_OCI_4` |
| Monitoring agent | on | B-07, checkov `CKV_OCI_6` |
| Boot volume encryption | Oracle-managed key; `kms_key_id` for a Vault key | B-03 |
| Backup policy | none | B-09 is set per blueprint; see Always Free note |
| Boot volume on destroy | removed | B-14, no orphaned volumes |
| Shape | `VM.Standard.A1.Flex`, 1 OCPU, 6 GB | two instances fit OCI Always Free |
| Tags | `var.tags` plus `managed-by=terraform`, `iac-module=oci/compute` | ADR 0004 |

Names (ADR 0004, `name` = prefix from `multi/naming`): `<name>-vm[-NN]`, `<name>-vnic[-NN]`;
`-NN` comes from `instance_number`.

OCI Always Free (checked 2026-10-21 in the Oracle documentation): A1.Flex 2 OCPUs and
12 GB in total; up to two `VM.Standard.E2.1.Micro`; 200 GB of block and boot volume storage
in total (each boot volume takes at least 50 GB); 5 volume backups; home region only.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | prefix from `multi/naming` (`<org>-<workload>-<env>-<region>`) |
| `instance_number` | number | `null` | appends `-NN` (1 to 99) |
| `compartment_id` | string | required | compartment OCID |
| `subnet_id` | string | required | subnet OCID for the primary VNIC |
| `image_id` | string | required | image OCID |
| `availability_domain` | number | `1` | AD number (1 to 3) |
| `fault_domain` | number | `null` | fault domain number (1 to 3) |
| `shape` | string | `VM.Standard.A1.Flex` | instance shape |
| `ocpus` | number | `1` | Flex shapes only |
| `memory_in_gbs` | number | `6` | Flex shapes only |
| `ssh_authorized_keys` | string | `null` | public keys, one per line |
| `user_data` | string | `null` | cloud-init, plain text; no secrets |
| `assign_public_ip` | bool | `false` | needs a public subnet |
| `nsg_ids` | list(string) | `[]` | network security groups |
| `hostname_label` | string | `null` | DNS hostname |
| `boot_volume_size_in_gbs` | number | `50` | minimum 50 |
| `boot_volume_vpus_per_gb` | number | `10` | 10 = balanced |
| `kms_key_id` | string | `null` | Vault key for the boot volume |
| `encrypt_in_transit` | bool | `true` | paravirtualized volume traffic |
| `backup_policy` | string | `null` | `bronze`, `silver`, `gold` or null |
| `preserve_boot_volume` | bool | `false` | keep boot volume after destroy |
| `tags` | map(string) | `{}` | freeform tags |
| `defined_tags` | map(string) | `null` | defined tags |

## Outputs

`instance_id`, `private_ip`, `public_ip`, `boot_volume_id`, `availability_domain`.

## Known gaps

- No block volume attachment, secondary VNICs, shielded instance or confidential computing
  options yet (A1 shapes support neither of the last two).
- Images are passed by OCID; platform images are replaced often, so pin the OCID in the
  consuming repository and review it monthly with the tooling versions.
- Some custom images do not support in-transit encryption; set `encrypt_in_transit = false`
  for those and record the exception (docs/frameworks.md).

## Tests

`tests/defaults.tftest.hcl`, mocked provider: secure defaults, fixed shape with AD, fault
domain, bronze backup, cloud-init and instance number, and rejection of a small boot volume,
an unknown backup policy, an instance number out of range and a malformed SSH key.

```bash
make test DIR=modules/oci/compute
```
