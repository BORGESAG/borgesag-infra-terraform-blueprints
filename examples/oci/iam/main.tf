provider "oci" {
  # Credentials come from ~/.oci/config (profile DEFAULT); nothing is set here.
  region = var.region
}

module "naming" {
  source = "../../../modules/multi/naming"

  org                 = "acme"
  workload            = "app"
  environment         = "lab"
  provider_name       = "oci"
  region              = var.region
  owner               = "platform-team"
  cost_center         = "cc-0000"
  data_classification = "internal"
  criticality         = "low"
  source_path         = "borgesag-infra-terraform-blueprints/examples/oci/iam"
}

# A workload compartment, a dynamic group for its instances, a policy that lets those
# instances read buckets in it, and the Object Storage service policy for lifecycle rules.
module "iam" {
  source = "../../../modules/oci/iam"

  name                  = module.naming.prefix
  tenancy_id            = var.tenancy_id
  parent_compartment_id = var.parent_compartment_id
  region                = var.region

  # Examples are disposable: delete the compartment on destroy (B-13 stays on in real use).
  compartment_enable_delete = true

  dynamic_groups = {
    app = {
      description   = "Instances of the workload compartment"
      matching_rule = "ALL {instance.compartment.id = '{compartment_id}'}"
    }
  }

  policies = {
    app = {
      description = "Workload instances read buckets and objects in their compartment"
      statements = [
        "Allow dynamic-group ${module.naming.prefix}-dg-app to read buckets in compartment id {compartment_id}",
        "Allow dynamic-group ${module.naming.prefix}-dg-app to read objects in compartment id {compartment_id}",
      ]
    }
  }

  object_storage_service_policy = true

  tags = module.naming.tags
}
