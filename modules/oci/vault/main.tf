# Written directly on the provider: the OCI Landing Zones vaults module declares the default
# oci provider as a configuration alias, so every caller would have to pass providers
# explicitly, and its grant policies name the compartment instead of its OCID. See README.

locals {
  tags = merge(var.tags, { "managed-by" = "terraform", "iac-module" = "oci/vault" })

  create_vault        = var.vault_id == null
  management_endpoint = local.create_vault ? oci_kms_vault.this[0].management_endpoint : data.oci_kms_vault.existing[0].management_endpoint

  # ECDSA keys take the curve from the key length.
  ecdsa_curves = { "32" = "NIST_P256", "48" = "NIST_P384", "66" = "NIST_P521" }

  key_versions = merge({}, [for k, v in var.keys : { for ver in v.versions : "${k}.${ver}" => k }]...)

  # Each key starts with one version; every entry in versions adds one.
  hsm_key_versions = sum(concat([0], [for v in values(var.keys) : 1 + length(v.versions) if v.protection_mode == "HSM"]))

  key_grants = { for k, v in var.keys : k => concat(
    [for s in v.service_grantees : "Allow service ${s} to use keys in compartment id ${var.compartment_id} where target.key.id = '${oci_kms_key.this[k].id}'"],
    [for g in v.group_grantees : "Allow group ${g} to use key-delegate in compartment id ${var.compartment_id} where target.key.id = '${oci_kms_key.this[k].id}'"],
    [for d in v.dynamic_group_grantees : "Allow dynamic-group ${d} to use key-delegate in compartment id ${var.compartment_id} where target.key.id = '${oci_kms_key.this[k].id}'"]
  ) }
}

data "oci_kms_vault" "existing" {
  count    = local.create_vault ? 0 : 1
  vault_id = var.vault_id
}

# DEFAULT is the shared-partition vault covered by OCI Always Free.
resource "oci_kms_vault" "this" {
  count = local.create_vault ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${var.name}-kv"
  vault_type     = "DEFAULT"

  freeform_tags = local.tags
  defined_tags  = var.defined_tags
}

resource "oci_kms_key" "this" {
  for_each = var.keys

  compartment_id      = var.compartment_id
  display_name        = "${var.name}-key-${each.key}"
  management_endpoint = local.management_endpoint
  protection_mode     = each.value.protection_mode

  key_shape {
    algorithm = each.value.algorithm
    length    = each.value.length
    curve_id  = each.value.algorithm == "ECDSA" ? local.ecdsa_curves[tostring(each.value.length)] : null
  }

  freeform_tags = local.tags
  defined_tags  = var.defined_tags

  # Services that use the key (buckets, volumes) are updated before an old key is deleted.
  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.hsm_key_version_limit == null || local.hsm_key_versions <= coalesce(var.hsm_key_version_limit, 0)
      error_message = "HSM key versions (${local.hsm_key_versions}) exceed hsm_key_version_limit: use SOFTWARE keys, fewer rotations, or raise the limit on a paid tenancy."
    }
  }
}

# Each label in versions creates one key version (manual rotation).
resource "oci_kms_key_version" "this" {
  for_each = local.key_versions

  key_id              = oci_kms_key.this[each.value].id
  management_endpoint = local.management_endpoint
}

resource "oci_identity_policy" "key_grants" {
  for_each = { for k, v in local.key_grants : k => v if length(v) > 0 }

  compartment_id = var.compartment_id
  name           = "${var.name}-pol-key-${each.key}"
  description    = "Use of key ${var.name}-key-${each.key}, managed by Terraform"
  statements     = each.value

  freeform_tags = local.tags
  defined_tags  = var.defined_tags
}
