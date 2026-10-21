output "prefix" {
  description = "Name prefix <org>-<workload>-<env>-<region>; pass it as the name input of other modules."
  value       = local.prefix

  precondition {
    condition     = local.region_code != "__missing__"
    error_message = "No short code for region ${var.region}: set region_code."
  }
}

output "region_code" {
  description = "Short region code used in the prefix."
  value       = local.region_code
}

output "abbreviations" {
  description = "Resource type abbreviations (ADR 0004)."
  value       = local.abbreviations
}

output "tags" {
  description = "Standard tags; pass them as the tags input of other modules."
  value       = local.tags
}
