provider "oci" {
  # Credentials come from ~/.oci/config (profile DEFAULT); nothing is set here.
  region = var.region
}

module "naming" {
  source = "../../../modules/multi/naming"

  org                 = "acme"
  workload            = "gov"
  environment         = "lab"
  provider_name       = "oci"
  region              = var.region
  owner               = "platform-team"
  cost_center         = "cc-0000"
  data_classification = "internal"
  criticality         = "low"
  source_path         = "borgesag-infra-terraform-blueprints/examples/oci/defined-tags"
}

# Defined tags for budgets and tag-based policies, mirroring three ADR 0004 tag keys.
# Defaults apply only to new resources in the sandbox compartment.
module "defined_tags" {
  source = "../../../modules/oci/defined-tags"

  name           = module.naming.prefix
  tenancy_id     = var.tenancy_id
  compartment_id = var.compartment_id

  tag_definitions = {
    cost-center = {
      description   = "Cost center code"
      cost_tracking = true
      default       = { value = "cc-0000", compartment_ids = [var.compartment_id] }
    }
    environment = {
      description = "Environment of the resource"
      values      = ["dev", "tst", "stg", "prd", "lab", "sbx"]
      default     = { value = "lab", compartment_ids = [var.compartment_id] }
    }
    data-classification = {
      description = "Data classification"
      values      = ["public", "internal", "confidential"]
    }
  }

  tags = module.naming.tags
}
