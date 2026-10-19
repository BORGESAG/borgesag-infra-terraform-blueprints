# 0002. Build on official and verified upstream modules

Date: 2026-10-19. Status: Accepted.

## Context

Mature, maintained module libraries exist for every target provider. Writing resources
from scratch duplicates their work and their bugs.

## Decision

Modules here are thin wrappers that set secure defaults, naming and tags on top of:

| Provider | Upstream |
|---|---|
| AWS | `terraform-aws-modules` |
| Azure | Azure Verified Modules (`Azure/avm-*`), status Available only |
| GCP | `terraform-google-modules` and Cloud Foundation Fabric |
| OCI | `oracle-terraform-modules` and OCI Landing Zones |
| Proxmox | provider `bpg/proxmox` (no module library; resources written here) |

Rules:

- Pin each upstream module to an exact version (registry) or tag (git).
- Write a resource directly only when no maintained upstream module covers it; say why in
  the module README.
- Copied upstream code keeps its license header and is listed in `NOTICE.md`.

## Consequences

- Upstream fixes arrive by bumping a version, reviewed through the changelog.
- A wrapper cannot expose more than the upstream module allows; when it must, the module
  README records the gap.
