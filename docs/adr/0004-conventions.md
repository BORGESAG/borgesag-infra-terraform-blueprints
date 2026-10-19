# 0004. Naming, tagging, variables and release tags

Date: 2026-10-19. Status: Accepted.

## Context

Consumers combine modules from several providers. Inputs, names and tags must look the
same everywhere so that a blueprint can be read without opening each module.

## Decision

Folders and files: lowercase kebab-case (`modules/oci/network`); Terraform identifiers in
snake_case; the main resource of a module is named `this`.

Resource names: `<name>-<resource>` by default, where `name` is an input built by the
consumer (for example `<org>-<workload>-<env>-<region>`). Provider limits on length and
characters are enforced with `validation` blocks.

Common inputs, same name and meaning in every module:

| Variable | Type | Notes |
|---|---|---|
| `name` | string | base for resource names |
| `tags` | map(string) | merged with module defaults; on OCI mapped to freeform tags |
| `location` / `region` | string | provider term kept (`location` on Azure, `region` elsewhere) |

Mandatory tags, set by blueprints: `owner`, `environment`, `workload`, `managed-by=terraform`,
`source=<repo path>`.

Variables: every variable has `description` and `type`; secure defaults (encryption on,
public access off); `validation` blocks for formats; no provider blocks inside modules.

Release tags: `<provider>-<module>/vX.Y.Z` (for example `oci-network/v0.1.0`), semantic
versioning, one CHANGELOG entry per tag.

## Consequences

- Renaming an input is a breaking change and needs a major version.
- Provider naming rules that conflict with the default pattern are documented per module.
