# oci/network

One VCN with private-by-default subnets, a locked default security list and optional
internet, NAT and service gateways.

- Upstream: [oci-landing-zones/terraform-oci-modules-networking](https://github.com/oci-landing-zones/terraform-oci-modules-networking)
  `v0.9.0` (UPL-1.0), called by commit `b8a21c9` (the v0.9.0 tag); no code copied.
- Validation level: L1, 2026-10-21 on the Linux validation host (pre-commit all hooks
  passed; `terraform test` 5 passed; terraform 1.16.5, trivy 0.75.0, checkov 3.3.29).
  L2 not run, so releases stay at v0.x (ADR 0003).
- Example: [examples/oci/network](../../../examples/oci/network).

## Why this upstream

ADR 0002 lists `oracle-terraform-modules` and OCI Landing Zones. `terraform-oci-vcn` v4.0.0
was reviewed first and not used:

- it calls `terraform-oci-logging` from git without a ref, so `terraform init` always pulls
  an unpinned module (ADR 0005);
- it ignores changes to `freeform_tags` and `defined_tags`, so tag drift is never fixed (B-08);
- subnets are public unless told otherwise (B-05).

The Landing Zones module pins nothing outside itself, applies tag changes and runs CIS
checks on security rules (`enable_cis_checks`).

## Defaults

| Setting | Default | Reason |
|---|---|---|
| Subnets | private (`prohibit_public_ip_on_vnic`, `prohibit_internet_ingress`) | B-05 |
| Default security list | no ingress, no egress rules | open traffic per workload with NSGs |
| Gateways | none | NAT and service gateways are not OCI Always Free |
| Tags | `var.tags` plus `managed-by=terraform`, `iac-module=oci/network` | ADR 0004 |
| CIS checks | on | upstream rejects 0.0.0.0/0 in the default security list |

Names (ADR 0004, `name` = prefix from `multi/naming`): `<name>-vcn`, `<name>-snet-<key>`,
`<name>-rt-public`, `<name>-rt-private`, `<name>-igw`, `<name>-ngw`, `<name>-sgw`,
`<name>-sl-default`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | prefix from `multi/naming` (`<org>-<workload>-<env>-<region>`) |
| `compartment_id` | string | required | compartment OCID |
| `cidr_blocks` | list(string) | required | VCN IPv4 CIDRs |
| `dns_label` | string | `null` | VCN DNS label; null disables DNS hostnames |
| `subnets` | map(object) | `{}` | `cidr_block`, `public` (false), `dns_label` |
| `create_internet_gateway` | bool | `false` | internet gateway and public route table |
| `create_nat_gateway` | bool | `false` | NAT gateway on the private route table |
| `create_service_gateway` | bool | `false` | service gateway (all services) on the private route table |
| `enable_cis_checks` | bool | `true` | upstream CIS checks |
| `tags` | map(string) | `{}` | freeform tags |
| `defined_tags` | map(string) | `null` | defined tags |

## Outputs

`vcn_id`, `subnet_ids` (keyed like `subnets`), `route_table_ids` (`rt-private`,
`rt-public`), `internet_gateway_id`, `nat_gateway_id`, `service_gateway_id`.

## Known gaps

- No NSGs, custom security lists, DRG, IPv6 or flow logs yet; add them as inputs when a
  blueprint needs them.
- The upstream module reads `route_rules[...].cidr_block`, which the OCI provider marks as
  deprecated; `terraform test` prints the warning. Follow upstream releases.
- The upstream module also uses `hashicorp/time` (`time_sleep`) without a version
  constraint; the example lock file pins it.
- On Windows, `terraform init` needs git long paths for the upstream clone
  (`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.longpaths GIT_CONFIG_VALUE_0=true`).

## Tests

`tests/defaults.tftest.hcl`, mocked provider: private defaults, public subnet with all
gateways, and rejection of a bad name, a bad CIDR and a public subnet without an internet
gateway.

```bash
make test DIR=modules/oci/network
```
