variable "name" {
  description = "Base for resource names (<name>-<resource>), for example org-workload-env-region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 50 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "compartment_id" {
  description = "OCID of the compartment for the vault, keys and grant policies."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "vault_id" {
  description = "OCID of an existing vault for the keys; null creates <name>-kv (shared-partition DEFAULT vault)."
  type        = string
  default     = null

  validation {
    condition     = var.vault_id == null || can(regex("^ocid1\\.vault\\.", coalesce(var.vault_id, "x")))
    error_message = "vault_id must be a vault OCID, or null."
  }
}

variable "keys" {
  description = "Master encryption keys keyed by role (<name>-key-<key>). Add an entry to versions to rotate a key. Grantees get a policy <name>-pol-key-<key> limited to that key."
  type = map(object({
    algorithm              = optional(string, "AES")
    length                 = optional(number, 32)
    protection_mode        = optional(string, "HSM")
    versions               = optional(list(string), [])
    service_grantees       = optional(list(string), [])
    group_grantees         = optional(list(string), [])
    dynamic_group_grantees = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.keys) : can(regex("^[a-z0-9]{1,15}$", k))])
    error_message = "keys map keys must be 1 to 15 lowercase letters or digits."
  }

  validation {
    condition = alltrue([for v in values(var.keys) : contains(["HSM", "SOFTWARE"], v.protection_mode) && (
      (v.algorithm == "AES" && contains([16, 24, 32], v.length)) ||
      (v.algorithm == "RSA" && contains([256, 384, 512], v.length)) ||
    (v.algorithm == "ECDSA" && contains([32, 48, 66], v.length)))])
    error_message = "protection_mode must be HSM or SOFTWARE; length must be 16, 24 or 32 for AES, 256, 384 or 512 for RSA, 32, 48 or 66 for ECDSA (bytes)."
  }

  validation {
    condition     = alltrue([for v in values(var.keys) : alltrue([for g in concat(v.service_grantees, v.group_grantees, v.dynamic_group_grantees) : can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$", g))])])
    error_message = "Grantees must be service, group or dynamic group names (letters, digits, '.', '_', '-')."
  }

  validation {
    condition     = alltrue([for v in values(var.keys) : length(v.versions) == length(distinct(v.versions))])
    error_message = "Key versions must be unique labels."
  }
}

variable "hsm_key_version_limit" {
  description = "Maximum HSM key versions this module may create (OCI Always Free covers 20 per tenancy); null disables the check."
  type        = number
  default     = 20

  validation {
    condition     = var.hsm_key_version_limit == null || try(var.hsm_key_version_limit >= 0, false)
    error_message = "hsm_key_version_limit must be 0 or more, or null."
  }
}

variable "tags" {
  description = "Freeform tags, merged with managed-by=terraform."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value)."
  type        = map(string)
  default     = null
}
