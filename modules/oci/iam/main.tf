locals {
  tags = merge(var.tags, { "managed-by" = "terraform", "iac-module" = "oci/iam" })

  create_compartment = var.compartment_id == null
  compartment_id     = local.create_compartment ? module.compartment[0].compartments["workload"].id : var.compartment_id

  # "{compartment_id}" in statements and matching rules is replaced by the workload compartment OCID.
  service_policies = var.object_storage_service_policy ? {
    objectstorage = {
      description = "Object Storage lifecycle actions on objects in the workload compartment"
      statements  = ["Allow service objectstorage-${coalesce(var.region, "unset")} to manage object-family in compartment id {compartment_id}"]
    }
  } : {}

  policies = merge(local.service_policies, var.policies)
}

module "compartment" {
  # v0.3.5
  source = "git::https://github.com/oci-landing-zones/terraform-oci-modules-iam.git//compartments?ref=3737ddf867f32bf6312511201f3e2cca4798cef6"
  count  = local.create_compartment ? 1 : 0

  tenancy_ocid = var.tenancy_id

  compartments_configuration = {
    enable_delete = var.compartment_enable_delete
    compartments = {
      workload = {
        name          = "${var.name}-cmp"
        description   = var.compartment_description
        parent_id     = coalesce(var.parent_compartment_id, var.tenancy_id)
        freeform_tags = local.tags
        defined_tags  = var.defined_tags
      }
    }
  }
}

module "dynamic_groups" {
  # v0.3.5
  source = "git::https://github.com/oci-landing-zones/terraform-oci-modules-iam.git//dynamic-groups?ref=3737ddf867f32bf6312511201f3e2cca4798cef6"
  count  = length(var.dynamic_groups) > 0 ? 1 : 0

  tenancy_ocid = var.tenancy_id

  dynamic_groups_configuration = {
    dynamic_groups = { for k, v in var.dynamic_groups : k => {
      name          = "${var.name}-dg-${k}"
      description   = v.description
      matching_rule = replace(v.matching_rule, "{compartment_id}", local.compartment_id)
      freeform_tags = local.tags
      defined_tags  = var.defined_tags
    } }
  }
}

module "policies" {
  # v0.3.5
  source = "git::https://github.com/oci-landing-zones/terraform-oci-modules-iam.git//policies?ref=3737ddf867f32bf6312511201f3e2cca4798cef6"
  count  = length(local.policies) > 0 ? 1 : 0

  tenancy_ocid = var.tenancy_id

  policies_configuration = {
    enable_cis_benchmark_checks = var.enable_cis_checks
    supplied_policies = { for k, v in local.policies : k => {
      name           = "${var.name}-pol-${k}"
      description    = v.description
      compartment_id = coalesce(try(v.compartment_id, null), local.compartment_id)
      statements     = [for s in v.statements : replace(s, "{compartment_id}", local.compartment_id)]
      freeform_tags  = local.tags
      defined_tags   = var.defined_tags
    } }
  }
}
