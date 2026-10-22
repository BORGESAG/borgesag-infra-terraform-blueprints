# Written directly on the provider: the OCI Landing Zones budgets module allows one alert rule
# per budget and defaults the start day to timestamp(), which changes on every plan. See README.

locals {
  tags = merge(var.tags, { "managed-by" = "terraform", "iac-module" = "oci/budget" })
  name = join("-", compact([var.name, "bdg", var.qualifier]))

  single_use = var.single_use != null
}

resource "oci_budget_budget" "this" {
  # Budgets always live in the root compartment, whatever they target.
  compartment_id = var.tenancy_id
  display_name   = local.name
  description    = var.description
  amount         = var.amount
  reset_period   = "MONTHLY"

  target_type = var.target_tag == null ? "COMPARTMENT" : "TAG"
  targets     = [var.target_tag == null ? coalesce(var.target_compartment_id, var.tenancy_id) : var.target_tag]

  processing_period_type                = local.single_use ? "SINGLE_USE" : "MONTH"
  budget_processing_period_start_offset = local.single_use ? null : var.start_day
  start_date                            = local.single_use ? "${var.single_use.start_date}T00:00:00Z" : null
  end_date                              = local.single_use ? "${var.single_use.end_date}T00:00:00Z" : null

  freeform_tags = local.tags
  defined_tags  = var.defined_tags
}

resource "oci_budget_alert_rule" "this" {
  for_each = var.alert_rules

  budget_id      = oci_budget_budget.this.id
  display_name   = "${local.name}-${each.key}"
  description    = "${each.value.type} spend at ${each.value.threshold}${each.value.threshold_type == "PERCENTAGE" ? "%" : ""} of budget ${local.name}"
  type           = each.value.type
  threshold_type = each.value.threshold_type
  threshold      = each.value.threshold
  recipients     = join(",", coalesce(each.value.recipients, var.recipients))
  message        = coalesce(each.value.message, "OCI budget ${local.name}: ${lower(each.value.type)} spend reached ${each.value.threshold}${each.value.threshold_type == "PERCENTAGE" ? "% of ${var.amount}" : ""} (rule ${each.key}).")

  freeform_tags = local.tags
  defined_tags  = var.defined_tags
}
