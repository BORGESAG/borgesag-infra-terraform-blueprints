# Modules

Thin wrappers over official or verified upstream modules (ADR 0002), one folder per
provider: `aws/`, `azure/`, `gcp/`, `oci/`, `proxmox/`.

Each module folder contains:

```text
main.tf  variables.tf  outputs.tf  versions.tf
README.md        purpose, upstream module and version, inputs/outputs, validation level
tests/           *.tftest.hcl with mock_provider (L1)
```

Tag format: `<provider>-<module>/vX.Y.Z` (ADR 0004).

| Module | Upstream | Level | Latest tag |
|---|---|---|---|
| [oci/network](oci/network) | oci-landing-zones/terraform-oci-modules-networking v0.9.0 | L1 | none |
| [multi/naming](multi/naming) | none (no provider) | L1 | none |
| [oci/compute](oci/compute) | none (provider resources; see README) | L1 | none |
| [oci/block-volume](oci/block-volume) | none (provider resources; see README) | L1 | none |
| [oci/object-storage](oci/object-storage) | none (provider resources; see README) | L1 | none |
| [oci/iam](oci/iam) | oci-landing-zones/terraform-oci-modules-iam v0.3.5 | L1 | none |
