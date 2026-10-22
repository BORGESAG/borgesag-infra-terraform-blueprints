output "vault_name" {
  description = "Name of the vault."
  value       = module.vault.vault_name
}

output "key_ids" {
  description = "Key OCIDs, for kms_key_id inputs."
  value       = module.vault.key_ids
}
