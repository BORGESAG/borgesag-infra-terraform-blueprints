output "compartment_id" {
  description = "OCID of the workload compartment (created or given)."
  value       = local.compartment_id
}

output "compartment_name" {
  description = "Name of the created compartment, or null when an existing one was given."
  value       = local.create_compartment ? module.compartment[0].compartments["workload"].name : null
}

output "dynamic_group_ids" {
  description = "Dynamic group OCIDs keyed like var.dynamic_groups."
  value       = length(var.dynamic_groups) > 0 ? { for k, v in module.dynamic_groups[0].dynamic_groups : k => v.id } : {}
}

output "dynamic_group_names" {
  description = "Dynamic group names keyed like var.dynamic_groups, for policy statements."
  value       = { for k in keys(var.dynamic_groups) : k => "${var.name}-dg-${k}" }
}

output "policy_ids" {
  description = "Policy OCIDs keyed like var.policies, plus objectstorage when enabled."
  value       = length(local.policies) > 0 ? { for k, v in module.policies[0].policies : k => v.id } : {}
}
