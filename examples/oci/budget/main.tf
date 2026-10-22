provider "oci" {
  # Credentials come from ~/.oci/config (profile DEFAULT); nothing is set here.
  region = var.region
}

module "naming" {
  source = "../../../modules/multi/naming"

  org                 = "acme"
  workload            = "finops"
  environment         = "lab"
  provider_name       = "oci"
  region              = var.region
  owner               = "platform-team"
  cost_center         = "cc-0000"
  data_classification = "internal"
  criticality         = "low"
  source_path         = "borgesag-infra-terraform-blueprints/examples/oci/budget"
}

# Free-tier guard: a tenancy-wide budget of 1 that alerts on any actual spend and when the
# month is forecast to exceed the budget.
module "budget" {
  source = "../../../modules/oci/budget"

  name       = module.naming.prefix
  tenancy_id = var.tenancy_id
  amount     = 1
  recipients = var.recipients

  alert_rules = {
    anyspend    = { threshold_type = "ABSOLUTE", threshold = 0.01, message = "OCI spend above zero: something left the free tier." }
    forecast100 = { type = "FORECAST", threshold = 100 }
  }

  tags = module.naming.tags
}
