# borgesag-infra-terraform-blueprints

Generic, validated Terraform building blocks for AWS, Azure, GCP, OCI and Proxmox.
Blueprints compose the official or verified upstream modules with guardrails, naming,
tagging, a security baseline, examples and documentation. Values in this repository are
always fictitious; real environments live in their own repositories and pin a tag of this one.

## Layout

```text
modules/<provider>/<module>/        thin wrappers over official/verified upstream modules
blueprints/<provider>/<pattern>/    opinionated compositions (landing zone, network, K8s cluster, ...)
examples/<provider>/<pattern>/      runnable examples with fictitious values
policies/                           custom checkov checks and OPA/conftest policies
docs/                               standards, framework mapping, testing
docs/adr/                           architecture decision records
ci-templates/                       pipeline templates, disabled (not run by any CI)
```

Provider values: `aws`, `azure`, `gcp`, `oci`, `proxmox`. Anything provider-neutral goes
under `multi`. See [ADR 0001](docs/adr/0001-repository-structure.md).

## Validation levels

| Level | What runs | Cost |
|---|---|---|
| L1 | `fmt`, `validate`, tflint, checkov, trivy, gitleaks, `terraform test` with `mock_provider` | none |
| L2 | real `terraform plan` against a sandbox account | none (read-only API calls) |
| L3 | `apply` + checks + `destroy`, evidence recorded | sandbox spend |

Every module and blueprint states its level in its README. See
[ADR 0003](docs/adr/0003-validation-levels.md).

Blueprints are also reviewed against CIS, NIST and the provider's well-architected
framework; the baseline controls and the checklist are in [docs/frameworks.md](docs/frameworks.md).

## Usage

```bash
make setup     # pinned tooling in .venv (pre-commit, checkov)
make lint      # pre-commit on all files (gitleaks, fmt, validate, tflint, checkov, trivy)
make test      # terraform test (L1, mocked providers) for every module with a tests/ folder
make versions  # compare pinned tool and provider versions with the latest releases
```

Consume a module by tag:

```hcl
module "network" {
  source = "git::https://github.com/BORGESAG/borgesag-infra-terraform-blueprints.git//modules/oci/network?ref=oci-network/v0.1.0"
}
```

## Status

Skeleton only. Modules and blueprints are added per provider; see [CHANGELOG.md](CHANGELOG.md).
