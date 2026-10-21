output "instance_id" {
  description = "OCID of the instance."
  value       = module.compute.instance_id
}

output "private_ip" {
  description = "Private IP of the instance."
  value       = module.compute.private_ip
}
