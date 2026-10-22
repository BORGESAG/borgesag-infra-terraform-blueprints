output "vault_id" {
  description = "OCID of the vault (created or given)."
  value       = local.create_vault ? oci_kms_vault.this[0].id : var.vault_id
}

output "vault_name" {
  description = "Name of the created vault, or null when an existing one was given."
  value       = local.create_vault ? oci_kms_vault.this[0].display_name : null
}

output "management_endpoint" {
  description = "Vault management endpoint."
  value       = local.management_endpoint
}

output "crypto_endpoint" {
  description = "Vault crypto endpoint."
  value       = local.create_vault ? oci_kms_vault.this[0].crypto_endpoint : data.oci_kms_vault.existing[0].crypto_endpoint
}

output "key_ids" {
  description = "Key OCIDs keyed like var.keys, for kms_key_id inputs (block volumes, buckets)."
  value       = { for k, v in oci_kms_key.this : k => v.id }
}

output "key_version_ids" {
  description = "Key version OCIDs keyed <key>.<label>."
  value       = { for k, v in oci_kms_key_version.this : k => v.key_version_id }
}

output "grant_policy_ids" {
  description = "Grant policy OCIDs keyed like var.keys (only keys with grantees)."
  value       = { for k, v in oci_identity_policy.key_grants : k => v.id }
}
