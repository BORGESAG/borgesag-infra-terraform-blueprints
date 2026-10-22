output "budget_id" {
  description = "OCID of the budget."
  value       = oci_budget_budget.this.id
}

output "budget_name" {
  description = "Name of the budget."
  value       = oci_budget_budget.this.display_name
}

output "alert_rule_ids" {
  description = "Alert rule OCIDs keyed like var.alert_rules."
  value       = { for k, v in oci_budget_alert_rule.this : k => v.id }
}
