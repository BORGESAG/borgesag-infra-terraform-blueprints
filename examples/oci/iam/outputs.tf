output "compartment_id" {
  description = "OCID of the workload compartment."
  value       = module.iam.compartment_id
}

output "compartment_name" {
  description = "Name of the workload compartment."
  value       = module.iam.compartment_name
}

output "dynamic_group_names" {
  description = "Dynamic group names."
  value       = module.iam.dynamic_group_names
}
