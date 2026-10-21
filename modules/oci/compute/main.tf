# Written directly on the provider: the maintained upstream (OCI Landing Zones workloads)
# always attaches an Oracle backup policy to the boot volume. See README.

locals {
  tags    = merge(var.tags, { "managed-by" = "terraform", "iac-module" = "oci/compute" })
  suffix  = var.instance_number == null ? "" : format("-%02d", var.instance_number)
  is_flex = length(regexall("\\.Flex$", var.shape)) > 0
  metadata = merge(
    var.ssh_authorized_keys != null ? { ssh_authorized_keys = var.ssh_authorized_keys } : {},
    var.user_data != null ? { user_data = base64encode(var.user_data) } : {}
  )
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[var.availability_domain - 1].name
  fault_domain        = var.fault_domain == null ? null : "FAULT-DOMAIN-${var.fault_domain}"
  display_name        = "${var.name}-vm${local.suffix}"
  shape               = var.shape

  dynamic "shape_config" {
    for_each = local.is_flex ? [1] : []
    content {
      ocpus         = var.ocpus
      memory_in_gbs = var.memory_in_gbs
    }
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb
    kms_key_id              = var.kms_key_id
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = var.assign_public_ip
    nsg_ids          = var.nsg_ids
    hostname_label   = var.hostname_label
    display_name     = "${var.name}-vnic${local.suffix}"
    freeform_tags    = local.tags
    defined_tags     = var.defined_tags
  }

  is_pv_encryption_in_transit_enabled = var.encrypt_in_transit

  launch_options {
    is_pv_encryption_in_transit_enabled = var.encrypt_in_transit
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  agent_config {
    is_monitoring_disabled = false
    is_management_disabled = false
  }

  metadata             = local.metadata
  preserve_boot_volume = var.preserve_boot_volume

  freeform_tags = local.tags
  defined_tags  = var.defined_tags
}

data "oci_core_volume_backup_policies" "oracle" {
  count = var.backup_policy == null ? 0 : 1
}

resource "oci_core_volume_backup_policy_assignment" "boot" {
  count = var.backup_policy == null ? 0 : 1

  asset_id  = oci_core_instance.this.boot_volume_id
  policy_id = one([for p in data.oci_core_volume_backup_policies.oracle[0].volume_backup_policies : p.id if p.display_name == var.backup_policy])
}
