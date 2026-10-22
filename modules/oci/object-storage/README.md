# oci/object-storage

One private Object Storage bucket with versioning and object events on, and optional
lifecycle rules for previous versions and unfinished multipart uploads.

- Upstream: none; resources written on provider `oracle/oci` (ADR 0002 exception, below).
- Validation level: L1, 2026-10-22 on the Linux validation host (pre-commit all hooks
  passed; `terraform test` 7 passed; terraform 1.16.5, trivy 0.75.0, checkov 3.3.29).
  L2 not run, so releases stay at v0.x (ADR 0003).
- Example: [examples/oci/storage](../../../examples/oci/storage).

## Why no upstream module

ADR 0002 allows direct resources when no maintained upstream module covers the need.
Neither `oracle-terraform-modules` nor OCI Landing Zones (networking, workloads, security,
observability, IAM, governance; checked 2026-10-22) publishes a bucket module.

## Defaults

| Setting | Default | Control |
|---|---|---|
| Public access | `NoPublicAccess`, not configurable | B-05, checkov `CKV_OCI_10` |
| Versioning | `Enabled` | checkov `CKV_OCI_8` |
| Object events | on | B-07, checkov `CKV_OCI_7` |
| Encryption at rest | Oracle-managed key; `kms_key_id` for a Vault key | B-03, checkov `CKV_OCI_9` skipped inline |
| Storage tier | `Standard`, auto-tiering off | |
| Lifecycle rules | none | needs the service IAM policy below |
| Tags | `var.tags` plus `managed-by=terraform`, `iac-module=oci/object-storage` | ADR 0004 |

Names (ADR 0004, `name` = prefix from `multi/naming`): `<name>-bkt[-<qualifier>]`. Bucket
names are unique within the tenancy namespace in a region.

OCI Always Free (checked 2026-10-22 in the Oracle documentation): 20 GB of Standard,
Infrequent Access and Archive data combined (10 GB each tier on paid accounts) and 50,000
API requests per month. With versioning on, previous versions count toward the 20 GB; set
`previous_version_retention_days` to keep that bounded.

## Lifecycle rules and IAM

Object Storage runs lifecycle actions as a service principal. Before setting
`previous_version_retention_days` or `multipart_upload_abort_days`, the tenancy needs a
policy such as:

```text
Allow service objectstorage-<region> to manage object-family in compartment <name>
```

Without it, creating the lifecycle policy fails at apply. The policy is not created here
(IAM is a separate module).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | prefix from `multi/naming` (`<org>-<workload>-<env>-<region>`) |
| `qualifier` | string | `null` | role after the type, for example `logs` |
| `compartment_id` | string | required | compartment OCID |
| `storage_tier` | string | `Standard` | or `Archive`; creation only |
| `auto_tiering` | string | `Disabled` | or `InfrequentAccess` (Standard only) |
| `versioning` | string | `Enabled` | `Enabled`, `Suspended`, `Disabled` |
| `object_events_enabled` | bool | `true` | emit object events |
| `kms_key_id` | string | `null` | Vault key |
| `previous_version_retention_days` | number | `null` | delete previous versions after N days |
| `multipart_upload_abort_days` | number | `null` | abort unfinished uploads after N days |
| `tags` | map(string) | `{}` | freeform tags |
| `defined_tags` | map(string) | `null` | defined tags |

## Outputs

`bucket_id`, `name`, `namespace`.

## Known gaps

- No retention rules (WORM), replication, pre-authenticated requests or custom lifecycle
  rules for current objects yet.
- No deletion protection (B-13): OCI refuses to delete a non-empty bucket, which protects
  data but not an empty bucket.
- Once versioning is enabled the bucket can only be suspended; OCI rejects `Disabled`.

## Tests

`tests/defaults.tftest.hcl`, mocked provider: secure defaults, qualifier with both
lifecycle rules and auto-tiering, Archive tier, and rejection of auto-tiering on Archive,
an unknown versioning value, zero retention days and a bad qualifier.

```bash
make test DIR=modules/oci/object-storage
```
