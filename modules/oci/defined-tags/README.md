# oci/defined-tags

One defined tag namespace with its tag keys, optional value lists, cost tracking and tag
defaults, for budgets, cost reports and tag-based policies.

- Upstream: [oci-landing-zones/terraform-oci-modules-governance](https://github.com/oci-landing-zones/terraform-oci-modules-governance)
  `v0.1.6` (UPL-1.0), submodule `tags`, called by commit `c1adf85` (the v0.1.6 tag); no code
  copied.
- Validation level: L1, 2026-10-22 on the Linux validation host (pre-commit all hooks
  passed; `terraform test` 10 passed; terraform 1.16.5, trivy 0.75.0, checkov 3.3.29).
  L2 not run, so releases stay at v0.x (ADR 0003).
- Example: [examples/oci/defined-tags](../../../examples/oci/defined-tags).

## Why this upstream

The OCI Landing Zones governance module is the tags module used by the OCI Landing Zones
(v0.1.6, 2025-11-05, the latest release when checked on 2026-10-22). It pins nothing outside
itself, does not ignore tag changes and covers namespaces, keys, value lists, cost tracking,
tag defaults and the CIS `CreatedBy` / `CreatedOn` tags. Its last release is older than the
IAM module's, so check for a newer one before each module release. `oracle-terraform-modules`
has no tagging module.

## Defaults

| Setting | Default | Control |
|---|---|---|
| Namespace | `<name>-tns` in the tenancy root, or `compartment_id` | ADR 0004 |
| Tag keys | none; lowercase kebab-case, like the freeform tag keys of ADR 0004 | ADR 0004 |
| Value list | none (free text); `values` adds an ENUM validator | B-08 |
| Cost tracking | off per key; at most 10 per tenancy | B-12 |
| Tag defaults | none; a required default may not target the tenancy root | B-08 |
| CIS `CreatedBy` / `CreatedOn` | off; only created when the tenancy has no `Oracle-Tags` namespace | CIS (upstream) |
| Tags | `var.tags` plus `managed-by=terraform`, `iac-module=oci/defined-tags` | ADR 0004 |

The upstream also adds the freeform tag `ocilz-terraform-module` (submodule and version).

Use the `defined_tag_keys` output to fill the `defined_tags` input of other modules, for
example `{ (module.defined_tags.defined_tag_keys["cost-center"]) = "cc-0000" }`. Keys must
exist before a resource uses them, so apply this module first (separate state or
`depends_on`).

Tag namespaces and keys are tenancy-wide IAM objects: point the provider at the home region.
They are not billed and do not use OCI Always Free quota.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | prefix from `multi/naming` (`<org>-<workload>-<env>-<region>`) |
| `tenancy_id` | string | required | tenancy OCID |
| `compartment_id` | string | `null` | compartment that holds the namespace; null = root |
| `description` | string | `Defined tags, managed by Terraform` | namespace description |
| `tag_definitions` | map(object) | `{}` | `description`, `cost_tracking`, `values`, `retired`, `default` (`value`, `compartment_ids`, `required`) |
| `retired` | bool | `false` | retire the namespace and all its keys |
| `cis_created_tags` | bool | `false` | CIS `CreatedBy` / `CreatedOn` in `<name>-cis-tns` |
| `tags` | map(string) | `{}` | freeform tags |
| `defined_tags` | map(string) | `null` | defined tags of another namespace |

Rules checked at plan: keys are 1 to 63 lowercase letters, digits or hyphens and do not start
with `oci` or `orcl` (reserved); `values` has 1 to 100 entries; a default value is one of the
`values` unless it is an OCI variable such as `${iam.principal.name}`; at most 10
cost-tracking keys; a required default cannot target the tenancy root (it would block every
resource created without the tag).

## Outputs

`namespace_id`, `namespace_name`, `tag_ids`, `defined_tag_keys` (`<namespace>.<key>`),
`tag_default_ids` (keyed `<key>.<compartment OCID>`).

## Deleting

OCI deletes a namespace only when it is retired and empty, and deletes one tag key at a time;
each key deletion removes the tag from every resource and can take up to 48 hours. To remove
the module:

1. Set `retired = true` and apply (namespace and keys retired, no longer applicable).
2. Run `terraform destroy -parallelism=1`; the provider waits up to 12 hours per key.

A deleted name can be reused only after OCI marks it deleted. To keep a namespace and stop
managing it, remove the module from state instead (`terraform state rm`).

## Known gaps

- One namespace per module call; call the module again for another namespace.
- No tag-based policy statements here; write them in `oci/iam` with the `defined_tag_keys`
  output (for example `where target.resource.tag.<namespace>.<key> = '<value>'`).
- Oracle's tagging overview no longer states the limit of 10 cost-tracking keys; the figure
  comes from the Oracle A-Team tagging best practices. The module checks only its own keys.
- Changing a key's value list does not fix values already set on resources (OCI behavior).
- On Windows, `terraform init` needs git long paths for the upstream clone
  (`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.longpaths GIT_CONFIG_VALUE_0=true`).

## Tests

`tests/defaults.tftest.hcl`, mocked provider (the `Oracle-Tags` lookup returns no namespace):
namespace with a cost-tracking key, a value list and a required default; namespace in a
compartment with two defaults in the same compartment; retirement of namespace and keys;
CIS tags; and rejection of a bad key, a reserved key, a default outside the value list, a
required default at the root, 11 cost-tracking keys and a bad tenancy OCID.

```bash
make test DIR=modules/oci/defined-tags
```
