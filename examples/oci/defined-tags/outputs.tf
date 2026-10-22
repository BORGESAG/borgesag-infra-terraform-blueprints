output "namespace_name" {
  description = "Name of the tag namespace."
  value       = module.defined_tags.namespace_name
}

output "defined_tag_keys" {
  description = "Full defined tag names, for defined_tags inputs of other modules."
  value       = module.defined_tags.defined_tag_keys
}
