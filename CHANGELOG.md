# Changelog

All notable changes to this repository are documented here. Modules are versioned
independently with tags `<provider>-<module>/vX.Y.Z` (see ADR 0004).

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Repository skeleton: layout, pre-commit, Makefile, tflint config, disabled CI templates.
- ADRs 0001 to 0005: structure, upstream base, validation levels, conventions, version policy.
- Framework mapping (`docs/frameworks.md`): CIS, NIST CSF 2.0 / SP 800-53 and
  well-architected references per provider, baseline controls B-01 to B-14 and the
  blueprint checklist.
- Module `oci/network` over OCI Landing Zones networking v0.9.0: one VCN, private-by-default
  subnets, locked default security list, optional internet, NAT and service gateways;
  mocked `terraform test`; example `examples/oci/network` with lock file.

### Changed

- ADR 0002: git upstream modules are pinned by commit hash, tag in a comment (`CKV_TF_1`).
- `requirements.txt` pins `numpy==2.3.5` so checkov runs on CPUs without x86-64-v2.
