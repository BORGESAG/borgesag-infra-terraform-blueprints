# 0003. Validation levels L1, L2, L3

Date: 2026-10-19. Status: Accepted.

## Context

Code in this repository is meant to be trusted as a reference. Trust has to be shown,
not claimed, and full apply tests cost money on every provider.

## Decision

| Level | Checks | Required for |
|---|---|---|
| L1 | `terraform fmt`, `validate`, tflint, checkov, trivy, gitleaks, `terraform test` with `mock_provider` | every commit to `main` |
| L2 | `terraform plan` of the example against a sandbox account | a module's first tag |
| L3 | `apply`, functional checks, `destroy`, evidence recorded | blueprints marked production-ready |

Each module and blueprint README has a "Validation" section with the level reached, the
date, the Terraform and provider versions, and where the evidence is.

## Consequences

- L1 runs locally (`make lint`, `make test`) with no credentials and no cost.
- L2 and L3 need sandbox credentials outside this repository and the owner's approval.
- A module without L2 is released only as `v0.x`.
