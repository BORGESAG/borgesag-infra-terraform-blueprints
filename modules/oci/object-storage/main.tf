# Written directly on the provider: no maintained upstream module manages Object Storage
# buckets (OCI Landing Zones has none). See README.

locals {
  tags = merge(var.tags, { "managed-by" = "terraform", "iac-module" = "oci/object-storage" })
  name = join("-", compact([var.name, "bkt", var.qualifier]))

  lifecycle_rules = concat(
    var.previous_version_retention_days == null ? [] : [{
      name        = "delete-previous-versions"
      action      = "DELETE"
      target      = "previous-object-versions"
      time_amount = var.previous_version_retention_days
    }],
    var.multipart_upload_abort_days == null ? [] : [{
      name        = "abort-multipart-uploads"
      action      = "ABORT"
      target      = "multipart-uploads"
      time_amount = var.multipart_upload_abort_days
    }]
  )
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

resource "oci_objectstorage_bucket" "this" {
  # checkov:skip=CKV_OCI_9:customer-managed key is the kms_key_id input; default is Oracle-managed encryption at rest (B-03)
  compartment_id        = var.compartment_id
  namespace             = data.oci_objectstorage_namespace.this.namespace
  name                  = local.name
  access_type           = "NoPublicAccess"
  storage_tier          = var.storage_tier
  auto_tiering          = var.auto_tiering
  versioning            = var.versioning
  object_events_enabled = var.object_events_enabled
  kms_key_id            = var.kms_key_id

  freeform_tags = local.tags
  defined_tags  = var.defined_tags
}

resource "oci_objectstorage_object_lifecycle_policy" "this" {
  count = length(local.lifecycle_rules) > 0 ? 1 : 0

  namespace = oci_objectstorage_bucket.this.namespace
  bucket    = oci_objectstorage_bucket.this.name

  dynamic "rules" {
    for_each = local.lifecycle_rules
    content {
      name        = rules.value.name
      action      = rules.value.action
      target      = rules.value.target
      time_amount = rules.value.time_amount
      time_unit   = "DAYS"
      is_enabled  = true
    }
  }
}
