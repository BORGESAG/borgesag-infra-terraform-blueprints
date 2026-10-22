output "namespace_id" {
  description = "OCID of the tag namespace."
  value       = module.tags.tag_namespaces["workload"].id
}

output "namespace_name" {
  description = "Name of the tag namespace."
  value       = local.namespace_name
}

output "tag_ids" {
  description = "Tag key OCIDs keyed like var.tag_definitions."
  value       = { for k in keys(var.tag_definitions) : k => module.tags.tags[k].id }
}

output "defined_tag_keys" {
  description = "Full defined tag names (<namespace>.<key>) keyed like var.tag_definitions, for defined_tags inputs and policy conditions."
  value       = { for k in keys(var.tag_definitions) : k => "${local.namespace_name}.${k}" }
}

output "tag_default_ids" {
  description = "Tag default OCIDs keyed by <key>.<compartment OCID>."
  value       = { for k, v in module.tags.tag_defaults : k => v.id if !startswith(k, "CIS-") }
}
