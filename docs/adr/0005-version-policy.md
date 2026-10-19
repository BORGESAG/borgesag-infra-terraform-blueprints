# 0005. Version policy

Date: 2026-10-19. Status: Accepted.

## Context

References that go stale stop being references. Unpinned versions make results change
without a commit.

## Decision

- Terraform: `required_version = ">= 1.16, < 2.0"` in modules; tooling pinned to an exact
  release in `docs/tooling.md`.
- Providers in modules: lower bound plus the next major as upper bound
  (`>= 7.0, < 8.0`); examples commit `.terraform.lock.hcl`.
- Upstream modules, pre-commit hooks and Python tools: exact versions.
- Only versions supported by the vendor; a version is bumped after reading its changelog,
  and the bump is recorded in CHANGELOG.md.
- `make versions` lists what is behind; it is reviewed monthly.

## Consequences

- Modules stay usable across provider minor releases; examples stay reproducible.
- Monthly review is manual by design (no scheduled CI); a bump that breaks L1 is not merged.
