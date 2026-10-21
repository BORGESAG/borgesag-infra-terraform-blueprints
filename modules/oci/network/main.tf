locals {
  tags = merge(var.tags, { "managed-by" = "terraform", "iac-module" = "oci/network" })

  public_route_rules = var.create_internet_gateway ? {
    internet = {
      network_entity_id = "igw"
      description       = "Internet through the internet gateway"
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
    }
  } : {}

  private_route_rules = merge(
    var.create_nat_gateway ? {
      nat = {
        network_entity_id = "natgw"
        description       = "Internet egress through the NAT gateway"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
      }
    } : {},
    var.create_service_gateway ? {
      services = {
        network_entity_id = "sgw"
        description       = "OCI services through the service gateway"
        destination       = "all-services"
        destination_type  = "SERVICE_CIDR_BLOCK"
      }
    } : {}
  )

  route_tables = merge(
    var.create_internet_gateway ? {
      rt-public = {
        display_name = "${var.name}-rt-public"
        route_rules  = local.public_route_rules
      }
    } : {},
    {
      rt-private = {
        display_name = "${var.name}-rt-private"
        route_rules  = local.private_route_rules
      }
    }
  )

  subnets = {
    for k, s in var.subnets : k => {
      cidr_block                 = s.cidr_block
      display_name               = "${var.name}-snet-${k}"
      dns_label                  = s.dns_label
      prohibit_internet_ingress  = !s.public
      prohibit_public_ip_on_vnic = !s.public
      route_table_key            = s.public ? "rt-public" : "rt-private"
      security_list_keys         = ["default_security_list"]
    }
  }

  network_configuration = {
    default_compartment_id    = var.compartment_id
    default_freeform_tags     = local.tags
    default_defined_tags      = var.defined_tags
    default_enable_cis_checks = var.enable_cis_checks

    network_configuration_categories = {
      (var.name) = {
        vcns = {
          vcn = {
            display_name   = "${var.name}-vcn"
            cidr_blocks    = var.cidr_blocks
            dns_label      = var.dns_label
            is_ipv6enabled = false

            # No rules: traffic is opened per workload with network security groups.
            default_security_list = {
              display_name  = "${var.name}-sl-default"
              ingress_rules = []
              egress_rules  = []
            }

            route_tables = local.route_tables
            subnets      = local.subnets

            vcn_specific_gateways = {
              internet_gateways = var.create_internet_gateway ? {
                igw = {
                  enabled      = true
                  display_name = "${var.name}-igw"
                }
              } : {}
              nat_gateways = var.create_nat_gateway ? {
                natgw = {
                  display_name  = "${var.name}-ngw"
                  block_traffic = false
                }
              } : {}
              service_gateways = var.create_service_gateway ? {
                sgw = {
                  display_name = "${var.name}-sgw"
                  services     = "all-services"
                }
              } : {}
            }
          }
        }
      }
    }
  }
}

module "this" {
  # v0.9.0
  source = "git::https://github.com/oci-landing-zones/terraform-oci-modules-networking.git?ref=b8a21c997395a894523bb29b0375a4efaa5593ab"

  network_configuration = local.network_configuration
}
