mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [
        { name = "Exmp:EXAMPLE-REGION-1-AD-1", id = "ocid1.availabilitydomain.oc1..exampleone", compartment_id = "ocid1.tenancy.oc1..exampleuniqueid" },
        { name = "Exmp:EXAMPLE-REGION-1-AD-2", id = "ocid1.availabilitydomain.oc1..exampletwo", compartment_id = "ocid1.tenancy.oc1..exampleuniqueid" },
      ]
    }
  }

  mock_data "oci_core_volume_backup_policies" {
    defaults = {
      volume_backup_policies = [
        { id = "ocid1.volumebackuppolicy.oc1..examplebronze", display_name = "bronze" },
        { id = "ocid1.volumebackuppolicy.oc1..examplesilver", display_name = "silver" },
      ]
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
    condition     = oci_core_volume.this.display_name == "example-app-dev-bv"
    error_message = "The volume name must follow <name>-bv."
  }

  assert {
    condition     = oci_core_volume.this.size_in_gbs == "50" && oci_core_volume.this.vpus_per_gb == "10"
    error_message = "Default must be 50 GB, balanced performance."
  }

  assert {
    condition     = oci_core_volume.this.availability_domain == "Exmp:EXAMPLE-REGION-1-AD-1"
    error_message = "Availability domain 1 must be used by default."
  }

  assert {
    condition     = length(oci_core_volume_attachment.this) == 0 && length(oci_core_volume_backup_policy_assignment.this) == 0
    error_message = "No attachment and no backup policy by default."
  }

  assert {
    condition     = oci_core_volume.this.freeform_tags["managed-by"] == "terraform" && oci_core_volume.this.freeform_tags["iac-module"] == "oci/block-volume" && oci_core_volume.this.freeform_tags["environment"] == "dev"
    error_message = "Tags must merge the input with managed-by and iac-module."
  }

  assert {
    condition     = output.attachment_id == null
    error_message = "attachment_id must be null when detached."
  }
}

run "attached_with_backup" {
  command = apply

  variables {
    qualifier           = "data"
    volume_number       = 2
    availability_domain = 2
    instance_id         = "ocid1.instance.oc1.example.exampleuniqueid"
    device              = "/dev/oracleoci/oraclevdb"
    backup_policy       = "bronze"
  }

  assert {
    condition     = oci_core_volume.this.display_name == "example-app-dev-bv-data-02" && oci_core_volume_attachment.this[0].display_name == "example-app-dev-bv-data-02-att"
    error_message = "Qualifier and number must follow <name>-bv-<qualifier>-NN; attachment adds -att."
  }

  assert {
    condition     = oci_core_volume.this.availability_domain == "Exmp:EXAMPLE-REGION-1-AD-2"
    error_message = "Availability domain number must map to its name."
  }

  assert {
    condition     = oci_core_volume_attachment.this[0].attachment_type == "paravirtualized" && oci_core_volume_attachment.this[0].is_pv_encryption_in_transit_enabled && !oci_core_volume_attachment.this[0].is_read_only
    error_message = "Attachment must be paravirtualized, encrypted in transit and read-write by default."
  }

  assert {
    condition     = oci_core_volume_backup_policy_assignment.this[0].policy_id == "ocid1.volumebackuppolicy.oc1..examplebronze"
    error_message = "The bronze policy must be attached to the volume."
  }
}

run "iscsi_has_no_pv_encryption" {
  command = apply

  variables {
    instance_id     = "ocid1.instance.oc1.example.exampleuniqueid"
    attachment_type = "iscsi"
  }

  assert {
    condition     = oci_core_volume_attachment.this[0].attachment_type == "iscsi" && !oci_core_volume_attachment.this[0].is_pv_encryption_in_transit_enabled
    error_message = "iSCSI attachments must not request paravirtualized encryption."
  }
}

run "rejects_small_volume" {
  command = plan

  variables {
    size_in_gbs = 40
  }

  expect_failures = [var.size_in_gbs]
}

run "rejects_bad_vpus" {
  command = plan

  variables {
    vpus_per_gb = 15
  }

  expect_failures = [var.vpus_per_gb]
}

run "rejects_bad_qualifier" {
  command = plan

  variables {
    qualifier = "Data_1"
  }

  expect_failures = [var.qualifier]
}

run "rejects_unknown_backup_policy" {
  command = plan

  variables {
    backup_policy = "platinum"
  }

  expect_failures = [var.backup_policy]
}

run "rejects_bad_attachment_type" {
  command = plan

  variables {
    attachment_type = "nvme"
  }

  expect_failures = [var.attachment_type]
}
