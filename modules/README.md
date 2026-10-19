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
| (none yet) | | | |
