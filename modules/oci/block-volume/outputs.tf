output "volume_id" {
  description = "OCID of the block volume."
  value       = oci_core_volume.this.id
}

output "name" {
  description = "Display name of the block volume."
  value       = oci_core_volume.this.display_name
}

output "attachment_id" {
  description = "OCID of the volume attachment, or null when detached."
  value       = one(oci_core_volume_attachment.this[*].id)
}

output "device" {
  description = "Device path of the attachment, or null when detached or not set."
  value       = one(oci_core_volume_attachment.this[*].device)
}
