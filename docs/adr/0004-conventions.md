# 0004. Naming, tagging, variables and release tags

Date: 2026-10-19. Status: Accepted. Revised 2026-10-21: structured name prefix, type
abbreviations and four more mandatory tags, approved by the repository owner.

## Context

Consumers combine modules from several providers. Inputs, names and tags must look the
same everywhere so that a blueprint can be read without opening each module, and so that
any resource found in a console or a cost report can be traced to its owner, workload,
environment and code.

## Decision

Folders and files: lowercase kebab-case (`modules/oci/network`); Terraform identifiers in
snake_case; the main resource or upstream module call of a module is named `this`.

### Resource names

Pattern, general to specific:

```text
<org>-<workload>-<env>-<region>-<type>[-<qualifier>][-<nn>]
acme-web-dev-gru-vcn
acme-web-dev-gru-snet-app
acme-web-dev-gru-vm-01
```

| Segment | Rule |
|---|---|
| `org` | 2 to 10 lowercase letters or digits |
| `workload` | 2 to 15 lowercase letters or digits |
| `env` | `dev`, `tst`, `stg`, `prd`, `lab`, `sbx` |
| `region` | OCI region key (`gru`, `iad`); other providers pass a 2 to 4 character code |
| `type` | abbreviation from the table below |
| `qualifier` | optional role or key (`app`, `public`) |
| `nn` | two digits, only when several resources share the rest of the name |

The prefix `<org>-<workload>-<env>-<region>` is built by `modules/multi/naming` and passed
to every module as `name`; modules append `<type>[-<qualifier>][-<nn>]`. Provider limits on
length and characters are enforced with `validation` blocks; a module whose provider cannot
take this pattern documents its deviation.

| Resource | Abbreviation | Resource | Abbreviation |
|---|---|---|---|
| block volume | `bv` | network security group | `nsg` |
| bucket | `bkt` | route table | `rt` |
| instance | `vm` | security list | `sl` |
| internet gateway | `igw` | service gateway | `sgw` |
| Kubernetes cluster | `k8s` | subnet | `snet` |
| load balancer | `lb` | vault | `kv` |
| NAT gateway | `ngw` | VCN / VPC / VNet | `vcn` |
| VNIC | `vnic` | volume attachment | `att` |
| compartment | `cmp` | dynamic group | `dg` |
| IAM policy | `pol` | tag namespace | `tns` |
| budget | `bdg` | encryption key | `key` |

New abbreviations are added to this table and to `modules/multi/naming` together.

### Tags

| Tag | Values | Set by |
|---|---|---|
| `owner` | team or person accountable | `multi/naming` |
| `workload` | same as the name segment | `multi/naming` |
| `environment` | same as the name segment | `multi/naming` |
| `cost-center` | cost center code | `multi/naming` |
| `data-classification` | `public`, `internal`, `confidential` | `multi/naming` |
| `criticality` | `low`, `medium`, `high` | `multi/naming` |
| `source` | repository and path of the root module | `multi/naming` |
| `managed-by` | `terraform` | every module |
| `iac-module` | module path, for example `oci/compute` | every module |

Keys are lowercase kebab-case. Extra tags are allowed but never override these keys. No
timestamp tags (they change on every plan). On OCI these are freeform tags; defined tags
(namespace) are accepted as a separate input and are required for tag defaults and
tag-based policies.

### Common inputs

| Variable | Type | Notes |
|---|---|---|
| `name` | string | prefix from `multi/naming` |
| `tags` | map(string) | tags from `multi/naming`; merged with module tags |
| `location` / `region` | string | provider term kept (`location` on Azure, `region` elsewhere) |

Variables: every variable has `description` and `type`; secure defaults (encryption on,
public access off); `validation` blocks for formats; no provider blocks inside modules.

### Release tags

`<provider>-<module>/vX.Y.Z` (for example `oci-network/v0.1.0`), semantic versioning, one
CHANGELOG entry per tag.

## Consequences

- Names sort by organization, workload and environment in consoles and cost reports, and
  the type sits at a fixed position, so scripts can parse it.
- Renaming an input or changing a name pattern is a breaking change and needs a major
  version (forces resource replacement where the provider cannot rename in place).
- The naming module is the single place to change prefixes, abbreviations and tag keys.
