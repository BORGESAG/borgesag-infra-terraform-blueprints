mock_provider "oci" {
  mock_data "oci_objectstorage_namespace" {
    defaults = {
      namespace = "examplens"
    }
  }
}

variables {
  name           = "example-app-dev"
  compartment_id = "ocid1.compartment.oc1..exampleuniqueid"
  tags           = { environment = "dev" }
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = oci_objectstorage_bucket.this.name == "example-app-dev-bkt" && oci_objectstorage_bucket.this.namespace == "examplens"
    error_message = "The bucket name must follow <name>-bkt in the tenancy namespace."
  }

  assert {
    condition     = oci_objectstorage_bucket.this.access_type == "NoPublicAccess"
    error_message = "Buckets must never be public."
  }

  assert {
    condition     = oci_objectstorage_bucket.this.versioning == "Enabled" && oci_objectstorage_bucket.this.object_events_enabled
    error_message = "Versioning and object events must be on by default."
  }

  assert {
    condition     = oci_objectstorage_bucket.this.storage_tier == "Standard" && oci_objectstorage_bucket.this.auto_tiering == "Disabled"
    error_message = "Default must be Standard tier without auto-tiering."
  }

  assert {
    condition     = length(oci_objectstorage_object_lifecycle_policy.this) == 0
    error_message = "No lifecycle policy by default (it needs a service IAM policy)."
  }

  assert {
    condition     = oci_objectstorage_bucket.this.freeform_tags["managed-by"] == "terraform" && oci_objectstorage_bucket.this.freeform_tags["iac-module"] == "oci/object-storage" && oci_objectstorage_bucket.this.freeform_tags["environment"] == "dev"
    error_message = "Tags must merge the input with managed-by and iac-module."
  }
}

run "lifecycle_and_qualifier" {
  command = apply

  variables {
    qualifier                       = "logs"
    auto_tiering                    = "InfrequentAccess"
    previous_version_retention_days = 30
    multipart_upload_abort_days     = 7
  }

  assert {
    condition     = oci_objectstorage_bucket.this.name == "example-app-dev-bkt-logs"
    error_message = "The qualifier must follow <name>-bkt-<qualifier>."
  }

  assert {
    condition     = length(oci_objectstorage_object_lifecycle_policy.this[0].rules) == 2
    error_message = "Both lifecycle rules must be created."
  }

  assert {
    condition = alltrue([
      for r in oci_objectstorage_object_lifecycle_policy.this[0].rules :
      r.time_unit == "DAYS" && r.is_enabled && (
        (r.target == "previous-object-versions" && r.action == "DELETE" && r.time_amount == "30") ||
        (r.target == "multipart-uploads" && r.action == "ABORT" && r.time_amount == "7")
      )
    ])
    error_message = "Lifecycle rules must delete previous versions and abort multipart uploads after the given days."
  }
}

run "archive_tier" {
  command = apply

  variables {
    storage_tier = "Archive"
  }

  assert {
    condition     = oci_objectstorage_bucket.this.storage_tier == "Archive"
    error_message = "Archive tier must be accepted."
  }
}

run "rejects_auto_tiering_on_archive" {
  command = plan

  variables {
    storage_tier = "Archive"
    auto_tiering = "InfrequentAccess"
  }

  expect_failures = [var.auto_tiering]
}

run "rejects_bad_versioning" {
  command = plan

  variables {
    versioning = "On"
  }

  expect_failures = [var.versioning]
}

run "rejects_zero_retention" {
  command = plan

  variables {
    previous_version_retention_days = 0
  }

  expect_failures = [var.previous_version_retention_days]
}

run "rejects_bad_qualifier" {
  command = plan

  variables {
    qualifier = "Logs-Bucket"
  }

  expect_failures = [var.qualifier]
}
