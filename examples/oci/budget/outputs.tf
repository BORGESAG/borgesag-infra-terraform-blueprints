output "budget_name" {
  description = "Name of the budget."
  value       = module.budget.budget_name
}

output "alert_rule_ids" {
  description = "Alert rule OCIDs."
  value       = module.budget.alert_rule_ids
}
