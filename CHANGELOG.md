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
- Module `oci/compute` on provider resources (upstream forces a boot volume backup policy
  beyond OCI Always Free): private VNIC, legacy IMDS off, in-transit encryption, optional
  Oracle backup policy; mocked `terraform test`; example `examples/oci/compute`.
- Module `multi/naming`: name prefix `<org>-<workload>-<env>-<region>`, OCI region keys,
  type abbreviations and the standard tag set; examples use it.
- Module `oci/block-volume` on provider resources: volume with optional paravirtualized
  attachment encrypted in transit and optional Oracle backup policy; mocked `terraform test`.
- Module `oci/object-storage` on provider resources: private bucket, versioning and object
  events on, optional lifecycle rules for previous versions and multipart uploads; mocked
  `terraform test`.
- Example `examples/oci/storage`: compute with an attached data volume and a bucket within
  OCI Always Free; abbreviation `att` (volume attachment) added to ADR 0004 and `multi/naming`.
- Module `oci/iam` over OCI Landing Zones IAM v0.3.5 (compartments, dynamic groups,
  policies): workload compartment kept on destroy by default, CIS IAM checks, optional Object
  Storage service policy, `{compartment_id}` placeholder in statements; mocked
  `terraform test`; example `examples/oci/iam`; abbreviations `cmp`, `dg`, `pol` added.
- Module `oci/defined-tags` over OCI Landing Zones governance v0.1.6 (tags): one namespace
  with keys, value lists, cost tracking and tag defaults, optional CIS `CreatedBy` /
  `CreatedOn`; plan-time checks for reserved names, value lists, 10 cost-tracking keys and
  required defaults at the root; documented retire-then-destroy path; mocked
  `terraform test`; example `examples/oci/defined-tags`; abbreviation `tns` added.
- Module `oci/budget` on provider resources (upstream allows one alert rule per budget and
  derives the start day from `timestamp()`): budget on the tenancy, a compartment or a
  cost-tracking tag, monthly from a fixed day or one-time, several email alert rules on
  actual or forecast spend; mocked `terraform test`; example `examples/oci/budget`
  (free-tier guard); abbreviation `bdg` added.

### Changed

- ADR 0004 revised: structured name prefix, type abbreviations, mandatory tags
  `cost-center`, `data-classification`, `criticality` and module-set `iac-module`; module
  suffixes follow it (`snet-<key>`, `rt-public`, `ngw`, `sl-default`, `vm-NN`).
- ADR 0002: git upstream modules are pinned by commit hash, tag in a comment (`CKV_TF_1`).
- `requirements.txt` pins `numpy==2.3.5` so checkov runs on CPUs without x86-64-v2.
