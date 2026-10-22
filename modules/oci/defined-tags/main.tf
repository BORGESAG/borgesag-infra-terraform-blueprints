locals {
  tags = merge(var.tags, { "managed-by" = "terraform", "iac-module" = "oci/defined-tags" })

  namespace_name = "${var.name}-tns"
}

module "tags" {
  # v0.1.6
  source = "git::https://github.com/oci-landing-zones/terraform-oci-modules-governance.git//tags?ref=c1adf85926dd6d6ffc3334fa33c4a74eb050722e"

  tenancy_ocid = var.tenancy_id

  tags_configuration = {
    default_compartment_id = coalesce(var.compartment_id, var.tenancy_id)
    default_freeform_tags  = local.tags
    default_defined_tags   = var.defined_tags
    # The upstream creates CreatedBy and CreatedOn only when the tenancy has no Oracle-Tags namespace.
    cis_namespace_name = var.cis_created_tags ? "${var.name}-cis-tns" : null

    namespaces = {
      workload = {
        name        = local.namespace_name
        description = var.description
        is_retired  = var.retired
        tags = { for k, v in var.tag_definitions : k => {
          name             = k
          description      = v.description
          is_cost_tracking = v.cost_tracking
          # Retiring the namespace retires its keys; keep the state in line with OCI.
          is_retired   = var.retired || v.retired
          valid_values = v.values
          # The upstream keys tag defaults by "<map key>.<compartment>", so the tag key keeps them unique.
          tag_defaults = v.default == null ? null : {
            (k) = {
              compartment_ids  = v.default.compartment_ids
              default_value    = v.default.value
              is_user_required = v.default.required
            }
          }
        } }
      }
    }
  }
}
