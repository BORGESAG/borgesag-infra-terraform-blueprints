# oci/iam

Workload identity on OCI: one compartment (created or existing), dynamic groups and policies,
with CIS IAM checks and an optional Object Storage service policy.

- Upstream: [oci-landing-zones/terraform-oci-modules-iam](https://github.com/oci-landing-zones/terraform-oci-modules-iam)
  `v0.3.5` (UPL-1.0), submodules `compartments`, `dynamic-groups` and `policies`, called by
  commit `3737ddf` (the v0.3.5 tag); no code copied.
- Validation level: L1, 2026-10-22 on the Linux validation host (pre-commit all hooks
  passed; `terraform test` 8 passed; terraform 1.16.5, trivy 0.75.0, checkov 3.3.29).
  L2 not run, so releases stay at v0.x (ADR 0003).
- Example: [examples/oci/iam](../../../examples/oci/iam).

## Why this upstream

ADR 0002 lists `oracle-terraform-modules` and OCI Landing Zones. The Landing Zones IAM
module is maintained (v0.3.5, 2026-09-22), pins nothing outside itself, applies tag changes,
keeps compartments on destroy unless told otherwise and checks policies for CIS IAM 1.2 and
1.3. Not used: `oracle-terraform-modules/terraform-oci-iam` (last release v2.0.3,
2023-05-29) and the `terraform-oci-tdf-iam-*` modules (last pushed 2021 to 2023).

## Defaults

| Setting | Default | Control |
|---|---|---|
| Compartment | created as `<name>-cmp` under the tenancy root, or `parent_compartment_id` | B-06 |
| Compartment on destroy | kept, only removed from state (`compartment_enable_delete = false`) | B-13 |
| CIS checks | on: no `manage all-resources in tenancy`, no changes to Administrators | B-01 |
| Dynamic groups, policies | none | B-01, least privilege per workload |
| Object Storage service policy | off | needed by `oci/object-storage` lifecycle rules |
| Tags | `var.tags` plus `managed-by=terraform`, `iac-module=oci/iam` | ADR 0004 |

The upstream also adds the freeform tag `ocilz-terraform-module` (submodule and version).

Names (ADR 0004, `name` = prefix from `multi/naming`): `<name>-cmp`, `<name>-dg-<key>`,
`<name>-pol-<key>`; the service policy is `<name>-pol-objectstorage`.

`{compartment_id}` in policy statements and dynamic group matching rules is replaced by the
workload compartment OCID, so statements use `in compartment id {compartment_id}` and stay
valid when the compartment is renamed or nested. Dynamic group names come from the
`dynamic_group_names` output, or are written as `<name>-dg-<key>`.

IAM changes go to the home region: point the provider at it. IAM is not billed and does not
use OCI Always Free quota.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | prefix from `multi/naming` (`<org>-<workload>-<env>-<region>`) |
| `tenancy_id` | string | required | tenancy OCID |
| `compartment_id` | string | `null` | existing compartment; null creates `<name>-cmp` |
| `parent_compartment_id` | string | `null` | parent of the created compartment; null = root |
| `compartment_description` | string | `Workload compartment, managed by Terraform` | |
| `compartment_enable_delete` | bool | `false` | delete the compartment on destroy |
| `dynamic_groups` | map(object) | `{}` | `description`, `matching_rule` |
| `policies` | map(object) | `{}` | `description`, `statements`, optional `compartment_id` |
| `object_storage_service_policy` | bool | `false` | needs `region` |
| `region` | string | `null` | region identifier, for example `sa-saopaulo-1` |
| `enable_cis_checks` | bool | `true` | CIS IAM checks (here and upstream) |
| `tags` | map(string) | `{}` | freeform tags |
| `defined_tags` | map(string) | `null` | defined tags |

Map keys for `dynamic_groups` and `policies` are 1 to 15 lowercase letters or digits;
`objectstorage` is reserved.

## Outputs

`compartment_id`, `compartment_name` (null for an existing compartment),
`dynamic_group_ids`, `dynamic_group_names`, `policy_ids`.

## Known gaps

- No groups, users or identity domains: tenancies with identity domains manage them in the
  domain; add an input when a blueprint needs it. Dynamic groups use the legacy IAM API,
  which OCI maps to the Default domain.
- No defined-tag namespace or tag defaults: use [oci/defined-tags](../defined-tags) and its
  `defined_tag_keys` output in tag-based policy statements.
- Policy statements are checked only for the CIS rules above; review least privilege per
  workload (B-01).
- On Windows, `terraform init` needs git long paths for the upstream clone
  (`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.longpaths GIT_CONFIG_VALUE_0=true`).

## Tests

`tests/defaults.tftest.hcl`, mocked provider (compartment OCID and tenancy mocked because
the upstream parses them): protected compartment with defaults, policy in a created
compartment under a parent, existing compartment with a dynamic group and the Object Storage
service policy, and rejection of the service policy without region, the reserved key, a
`manage all-resources in tenancy` statement, a bad dynamic group key and a bad tenancy OCID.

```bash
make test DIR=modules/oci/iam
```
