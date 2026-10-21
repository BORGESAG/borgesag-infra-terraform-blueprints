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
  name                = "example-app-dev"
  compartment_id      = "ocid1.compartment.oc1..exampleuniqueid"
  subnet_id           = "ocid1.subnet.oc1.example.exampleuniqueid"
  image_id            = "ocid1.image.oc1.example.exampleuniqueid"
  ssh_authorized_keys = "ssh-ed25519 AAAAexamplepublickey example@host"
  tags                = { environment = "dev" }
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = oci_core_instance.this.display_name == "example-app-dev-vm"
    error_message = "The instance name must follow <name>-vm."
  }

  assert {
    condition     = oci_core_instance.this.create_vnic_details[0].assign_public_ip == "false"
    error_message = "No public IP by default."
  }

  assert {
    condition     = oci_core_instance.this.instance_options[0].are_legacy_imds_endpoints_disabled
    error_message = "Legacy IMDS endpoints must be disabled."
  }

  assert {
    condition     = oci_core_instance.this.launch_options[0].is_pv_encryption_in_transit_enabled && oci_core_instance.this.is_pv_encryption_in_transit_enabled
    error_message = "In-transit encryption must be on by default."
  }

  assert {
    condition     = oci_core_instance.this.shape_config[0].ocpus == 1 && oci_core_instance.this.shape_config[0].memory_in_gbs == 6
    error_message = "A1.Flex default must be 1 OCPU and 6 GB (fits OCI Always Free twice)."
  }

  assert {
    condition     = oci_core_instance.this.availability_domain == "Exmp:EXAMPLE-REGION-1-AD-1"
    error_message = "Availability domain 1 must be used by default."
  }

  assert {
    condition     = length(oci_core_volume_backup_policy_assignment.boot) == 0
    error_message = "No backup policy is attached by default."
  }

  assert {
    condition     = !oci_core_instance.this.preserve_boot_volume
    error_message = "The boot volume must be removed with the instance by default."
  }

  assert {
    condition     = oci_core_instance.this.freeform_tags["managed-by"] == "terraform" && oci_core_instance.this.freeform_tags["iac-module"] == "oci/compute" && oci_core_instance.this.freeform_tags["environment"] == "dev"
    error_message = "Tags must merge the input with managed-by=terraform."
  }

  assert {
    condition     = oci_core_instance.this.metadata["ssh_authorized_keys"] == var.ssh_authorized_keys && !contains(keys(oci_core_instance.this.metadata), "user_data")
    error_message = "Metadata must hold the SSH key and no user_data unless given."
  }
}

run "backup_ad_and_fixed_shape" {
  command = apply

  variables {
    shape               = "VM.Standard.E2.1.Micro"
    availability_domain = 2
    fault_domain        = 3
    backup_policy       = "bronze"
    user_data           = "#cloud-config\npackage_update: true\n"
    instance_number     = 2
  }

  assert {
    condition     = oci_core_instance.this.display_name == "example-app-dev-vm-02" && oci_core_instance.this.create_vnic_details[0].display_name == "example-app-dev-vnic-02"
    error_message = "instance_number must append -NN to the VM and VNIC names."
  }

  assert {
    condition     = length(oci_core_instance.this.shape_config) == 0
    error_message = "Fixed shapes must not get shape_config."
  }

  assert {
    condition     = oci_core_instance.this.availability_domain == "Exmp:EXAMPLE-REGION-1-AD-2" && oci_core_instance.this.fault_domain == "FAULT-DOMAIN-3"
    error_message = "Availability and fault domain numbers must map to names."
  }

  assert {
    condition     = oci_core_volume_backup_policy_assignment.boot[0].policy_id == "ocid1.volumebackuppolicy.oc1..examplebronze"
    error_message = "The bronze policy must be attached to the boot volume."
  }

  assert {
    condition     = base64decode(oci_core_instance.this.metadata["user_data"]) == var.user_data
    error_message = "user_data must be base64 encoded."
  }
}

run "rejects_small_boot_volume" {
  command = plan

  variables {
    boot_volume_size_in_gbs = 40
  }

  expect_failures = [var.boot_volume_size_in_gbs]
}

run "rejects_unknown_backup_policy" {
  command = plan

  variables {
    backup_policy = "platinum"
  }

  expect_failures = [var.backup_policy]
}

run "rejects_bad_instance_number" {
  command = plan

  variables {
    instance_number = 100
  }

  expect_failures = [var.instance_number]
}

run "rejects_bad_ssh_key" {
  command = plan

  variables {
    ssh_authorized_keys = "not-a-key"
  }

  expect_failures = [var.ssh_authorized_keys]
}
