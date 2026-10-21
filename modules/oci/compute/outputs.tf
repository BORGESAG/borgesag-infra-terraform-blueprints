output "instance_id" {
  description = "OCID of the instance."
  value       = oci_core_instance.this.id
}

output "private_ip" {
  description = "Private IP of the primary VNIC."
  value       = oci_core_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP of the primary VNIC, or empty when none is assigned."
  value       = oci_core_instance.this.public_ip
}

output "boot_volume_id" {
  description = "OCID of the boot volume."
  value       = oci_core_instance.this.boot_volume_id
}

output "availability_domain" {
  description = "Name of the availability domain used."
  value       = oci_core_instance.this.availability_domain
}
