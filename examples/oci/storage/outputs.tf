output "instance_id" {
  description = "OCID of the instance."
  value       = module.compute.instance_id
}

output "volume_id" {
  description = "OCID of the data volume."
  value       = module.data_volume.volume_id
}

output "volume_device" {
  description = "Device path of the data volume on the instance."
  value       = module.data_volume.device
}

output "bucket_name" {
  description = "Name of the bucket."
  value       = module.bucket.name
}
