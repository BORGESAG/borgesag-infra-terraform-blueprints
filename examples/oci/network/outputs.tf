output "vcn_id" {
  description = "OCID of the VCN."
  value       = module.network.vcn_id
}

output "subnet_ids" {
  description = "Subnet OCIDs."
  value       = module.network.subnet_ids
}
