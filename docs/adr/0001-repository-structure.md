# 0001. Repository structure

Date: 2026-10-19. Status: Accepted.

## Context

The repository must hold reusable Terraform for several providers, be generic by
default, and keep provider-specific code clearly separated. Real environments live in
other repositories and consume this one by tag.

## Decision

- One repository for Terraform across providers; Ansible and Kubernetes content stays in
  its own catalog repository.
- Top level by artifact type, then by provider:
  `modules/<provider>/<module>/`, `blueprints/<provider>/<pattern>/`,
  `examples/<provider>/<pattern>/`, plus `policies/`, `docs/`, `ci-templates/`.
- Provider values: `aws`, `azure`, `gcp`, `oci`, `proxmox`, and `multi` for
  provider-neutral code.
- No environment folders (`dev`, `prod`) and no state here; examples use fictitious values.
- CI definitions live only in `ci-templates/`, disabled.

## Consequences

- A consumer pins one module path and tag without pulling unrelated providers' code.
- Cross-provider changes (conventions, policies) happen in one pull request.
- Per-module tags are required because modules evolve at different speeds (ADR 0004).
