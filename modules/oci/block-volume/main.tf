# Written directly on the provider: the maintained upstream (OCI Landing Zones workloads)
# ships block volumes inside the compute module and requires a replication provider alias.
# See README.

locals {
  tags   = merge(var.tags, { "managed-by" = "terraform", "iac-module" = "oci/block-volume" })
  suffix = var.volume_number == null ? null : format("%02d", var.volume_number)
  name   = join("-", compact([var.name, "bv", var.qualifier, local.suffix]))
  attach = var.instance_id != null
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

resource "oci_core_volume" "this" {
  # checkov:skip=CKV_OCI_2:backup_policy_id is deprecated in the provider; backups use oci_core_volume_backup_policy_assignment
  # checkov:skip=CKV_OCI_3:customer-managed key is the kms_key_id input; default is Oracle-managed encryption at rest (B-03)
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[var.availability_domain - 1].name
  display_name        = local.name
  size_in_gbs         = var.size_in_gbs
  vpus_per_gb         = var.vpus_per_gb
  kms_key_id          = var.kms_key_id

  freeform_tags = local.tags
  defined_tags  = var.defined_tags
}

resource "oci_core_volume_attachment" "this" {
  count = local.attach ? 1 : 0

  instance_id                         = var.instance_id
  volume_id                           = oci_core_volume.this.id
  attachment_type                     = var.attachment_type
  display_name                        = "${local.name}-att"
  device                              = var.device
  is_read_only                        = var.read_only
  is_pv_encryption_in_transit_enabled = var.attachment_type == "paravirtualized" ? var.encrypt_in_transit : false
}

data "oci_core_volume_backup_policies" "oracle" {
  count = var.backup_policy == null ? 0 : 1
}

resource "oci_core_volume_backup_policy_assignment" "this" {
  count = var.backup_policy == null ? 0 : 1

  asset_id  = oci_core_volume.this.id
  policy_id = one([for p in data.oci_core_volume_backup_policies.oracle[0].volume_backup_policies : p.id if p.display_name == var.backup_policy])
}
