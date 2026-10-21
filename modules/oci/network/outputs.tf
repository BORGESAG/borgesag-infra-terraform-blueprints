output "vcn_id" {
  description = "OCID of the VCN."
  value       = module.this.provisioned_vcn_ids["vcn"].id
}

output "subnet_ids" {
  description = "Subnet OCIDs keyed like var.subnets."
  value       = { for k in keys(var.subnets) : k => module.this.provisioned_subnet_ids[k].id }
}

output "route_table_ids" {
  description = "Route table OCIDs: rt-private, and rt-public when the internet gateway exists."
  value       = { for k in keys(local.route_tables) : k => module.this.provisioned_route_table_ids[k].id }
}

output "internet_gateway_id" {
  description = "OCID of the internet gateway, or null."
  value       = try(module.this.provisioned_internet_gateway_ids["igw"].id, null)
}

output "nat_gateway_id" {
  description = "OCID of the NAT gateway, or null."
  value       = try(module.this.provisioned_nat_gateway_ids["natgw"].id, null)
}

output "service_gateway_id" {
  description = "OCID of the service gateway, or null."
  value       = try(module.this.provisioned_service_gateway_ids["sgw"].id, null)
}
