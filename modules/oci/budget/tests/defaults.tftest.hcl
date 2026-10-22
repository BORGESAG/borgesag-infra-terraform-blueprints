mock_provider "oci" {}

variables {
  name       = "example-app-dev"
  tenancy_id = "ocid1.tenancy.oc1..exampleuniqueid"
  amount     = 10
  recipients = ["ops@example.com"]
  tags       = { environment = "dev" }
}

run "monthly_tenancy_budget_with_default_rules" {
  command = apply

  assert {
    condition     = oci_budget_budget.this.display_name == "example-app-dev-bdg" && oci_budget_budget.this.compartment_id == var.tenancy_id
    error_message = "The budget must be <name>-bdg in the root compartment."
  }

  assert {
    condition     = oci_budget_budget.this.target_type == "COMPARTMENT" && oci_budget_budget.this.targets == tolist([var.tenancy_id])
    error_message = "The default target must be the whole tenancy."
  }

  assert {
    condition     = oci_budget_budget.this.processing_period_type == "MONTH" && oci_budget_budget.this.reset_period == "MONTHLY" && oci_budget_budget.this.budget_processing_period_start_offset == 1
    error_message = "The default must be a monthly budget starting on day 1."
  }

  assert {
    condition     = oci_budget_budget.this.freeform_tags["managed-by"] == "terraform" && oci_budget_budget.this.freeform_tags["iac-module"] == "oci/budget" && oci_budget_budget.this.freeform_tags["environment"] == "dev"
    error_message = "Tags must merge the input with managed-by and iac-module."
  }

  assert {
    condition     = length(oci_budget_alert_rule.this) == 3 && oci_budget_alert_rule.this["forecast100"].type == "FORECAST" && oci_budget_alert_rule.this["actual50"].type == "ACTUAL" && oci_budget_alert_rule.this["actual50"].threshold_type == "PERCENTAGE" && oci_budget_alert_rule.this["actual50"].threshold == 50
    error_message = "Default rules must be actual 50 %, actual 100 % and forecast 100 %."
  }

  assert {
    condition     = oci_budget_alert_rule.this["actual100"].display_name == "example-app-dev-bdg-actual100" && oci_budget_alert_rule.this["actual100"].recipients == "ops@example.com"
    error_message = "Rules must be named <budget>-<key> and use the shared recipients."
  }
}

run "compartment_target_and_custom_rules" {
  command = apply

  variables {
    qualifier             = "lab"
    target_compartment_id = "ocid1.compartment.oc1..exampleworkload"
    start_day             = 15
    alert_rules = {
      anyspend = { threshold_type = "ABSOLUTE", threshold = 0.01, recipients = ["a@example.com", "b@example.com"], message = "Spend left the free tier." }
    }
  }

  assert {
    condition     = oci_budget_budget.this.display_name == "example-app-dev-bdg-lab" && oci_budget_budget.this.targets == tolist(["ocid1.compartment.oc1..exampleworkload"]) && oci_budget_budget.this.budget_processing_period_start_offset == 15
    error_message = "qualifier, target compartment and start day must be applied."
  }

  assert {
    condition     = length(oci_budget_alert_rule.this) == 1 && oci_budget_alert_rule.this["anyspend"].threshold_type == "ABSOLUTE" && oci_budget_alert_rule.this["anyspend"].recipients == "a@example.com,b@example.com" && oci_budget_alert_rule.this["anyspend"].message == "Spend left the free tier."
    error_message = "Custom rules replace the defaults, with their own recipients and message."
  }
}

run "tag_target_single_use" {
  command = apply

  variables {
    target_tag = "example-gov-dev-tns.cost-center.cc-0000"
    single_use = { start_date = "2026-11-01", end_date = "2027-03-31" }
  }

  assert {
    condition     = oci_budget_budget.this.target_type == "TAG" && oci_budget_budget.this.targets == tolist(["example-gov-dev-tns.cost-center.cc-0000"])
    error_message = "target_tag must set a TAG budget."
  }

  assert {
    condition     = oci_budget_budget.this.processing_period_type == "SINGLE_USE" && oci_budget_budget.this.start_date == "2026-11-01T00:00:00Z" && oci_budget_budget.this.end_date == "2027-03-31T00:00:00Z"
    error_message = "single_use must set a one-time budget with fixed dates."
  }
}

run "rejects_both_targets" {
  command = plan

  variables {
    target_tag            = "ns.key.value"
    target_compartment_id = "ocid1.compartment.oc1..exampleworkload"
  }

  expect_failures = [var.target_tag]
}

run "rejects_fractional_amount" {
  command = plan

  variables {
    amount = 0.5
  }

  expect_failures = [var.amount]
}

run "rejects_single_use_over_one_year" {
  command = plan

  variables {
    single_use = { start_date = "2026-11-01", end_date = "2027-12-31" }
  }

  expect_failures = [var.single_use]
}

run "rejects_bad_rule" {
  command = plan

  variables {
    alert_rules = { actual = { type = "ACTUALS", threshold = 50 } }
  }

  expect_failures = [var.alert_rules]
}

run "rejects_bad_recipient" {
  command = plan

  variables {
    recipients = ["not-an-email"]
  }

  expect_failures = [var.recipients]
}
