# Notice

Modules in this repository call upstream modules by registry or git reference; that code
is not copied here and stays under its own license.

Code copied or adapted from third parties is listed below with its source, commit and
license (ADR 0002).

| Path | Source | Commit or version | License |
|---|---|---|---|
| modules/oci/network | OCI Landing Zones networking v0.9.0 | 8d04136 | Apache-2.0 |
| modules/oci/compute | OCI Landing Zones workloads v0.2.9 / oracle-terraform-modules/terraform-oci-compute-instance v2.4.1 | 93fa3dd / 2022-11-29 | Apache-2.0 |
| modules/oci/block-storage | OCI Landing Zones workloads v0.2.9 / oracle-terraform-modules/terraform-oci-tdf-block-storage v0.1.5 | 93fa3dd / 2022-11-29 | Apache-2.0 |
| modules/oci/iam | OCI Landing Zones IAM v0.3.5 | 45a9a67 | Apache-2.0 |
| modules/oci/defined-tags | OCI Landing Zones governance v0.1.6 | 2e1c903 | Apache-2.0 |
| modules/oci/vault | OCI Landing Zones security v0.2.3 / oracle-terraform-modules | f4f46df / 2025-11-07 | Apache-2.0 |
| modules/oci/budget | OCI Landing Zones budgets v0.1.6 | 273a14f | Apache-2.0 |
| docs/frameworks.md | CIS / NIST / Well-Architected Framework per provider | — | CC-BY 4.0 |
| docs/adr/0002-upstream-base | oracle-terraform-modules + OCI Landing Zones | — | Apache-2.0 |
