# multi/naming

Builds the name prefix and the standard tags from one set of inputs (ADR 0004). No
provider and no resources: plain computation, usable with any provider module.

- Validation level: L1 (`terraform test`, see Tests).

## Usage

```hcl
module "naming" {
  source = "../../modules/multi/naming"

  org                 = "acme"
  workload            = "web"
  environment         = "dev"
  provider_name       = "oci"
  region              = "sa-saopaulo-1"   # region key gru from the built-in table
  owner               = "platform-team"
  cost_center         = "cc-1001"
  data_classification = "internal"
  criticality         = "medium"
  source_path         = "example-repo/envs/dev"
}

module "network" {
  source = "../../modules/oci/network"
  name   = module.naming.prefix   # acme-web-dev-gru
  tags   = module.naming.tags
  # ...
}
```

Region codes: the official OCI region keys are built in (checked 2026-10-21 in the Oracle
documentation). AWS, Azure and GCP have no official short codes; pass `region_code`
(2 to 4 characters, for example `sae1`) and keep the same code across the repository.
A region without a code fails the plan.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `org` | string | required | 2 to 10 lowercase letters or digits |
| `workload` | string | required | 2 to 15 lowercase letters or digits |
| `environment` | string | required | `dev`, `tst`, `stg`, `prd`, `lab`, `sbx` |
| `provider_name` | string | required | `aws`, `azure`, `gcp`, `oci`, `proxmox` |
| `region` | string | required | provider region identifier |
| `region_code` | string | `null` | short code; required outside the OCI table |
| `owner` | string | required | tag `owner` |
| `cost_center` | string | required | tag `cost-center` |
| `data_classification` | string | required | `public`, `internal`, `confidential` |
| `criticality` | string | required | `low`, `medium`, `high` |
| `source_path` | string | required | tag `source` |
| `extra_tags` | map(string) | `{}` | added; never override standard keys |

## Outputs

`prefix`, `region_code`, `abbreviations` (resource type to abbreviation), `tags`.

## Tests

`tests/defaults.tftest.hcl`: OCI region key and exact tag set, extra tags that cannot
override standard keys, explicit region code, and rejection of an unknown region without a
code, a bad environment and a bad classification.

```bash
make test DIR=modules/multi/naming
```
