variable "name" {
  description = "Base for resource names (<name>-<resource>), for example org-workload-env-region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 50 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "qualifier" {
  description = "Role appended after the type (<name>-bkt-<qualifier>), for example logs; null for none."
  type        = string
  default     = null

  validation {
    condition     = var.qualifier == null || can(regex("^[a-z0-9]{1,15}$", coalesce(var.qualifier, "x")))
    error_message = "qualifier must be 1 to 15 lowercase letters or digits, or null."
  }
}

variable "compartment_id" {
  description = "OCID of the compartment for the bucket."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "storage_tier" {
  description = "Standard or Archive; set at creation only (a change replaces the bucket)."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Archive"], var.storage_tier)
    error_message = "storage_tier must be Standard or Archive."
  }
}

variable "auto_tiering" {
  description = "Disabled or InfrequentAccess (Standard tier only)."
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Disabled", "InfrequentAccess"], var.auto_tiering) && (var.auto_tiering == "Disabled" || var.storage_tier == "Standard")
    error_message = "auto_tiering must be Disabled or InfrequentAccess, and InfrequentAccess needs storage_tier Standard."
  }
}

variable "versioning" {
  description = "Enabled, Suspended or Disabled. Once enabled, a bucket can only be suspended, not disabled."
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Suspended", "Disabled"], var.versioning)
    error_message = "versioning must be Enabled, Suspended or Disabled."
  }
}

variable "object_events_enabled" {
  description = "Emit object events to the OCI Events service."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "OCID of a Vault key; null uses Oracle-managed keys."
  type        = string
  default     = null
}

variable "previous_version_retention_days" {
  description = "Delete previous object versions after this many days; null keeps them. Needs the Object Storage service IAM policy (README)."
  type        = number
  default     = null

  validation {
    condition     = var.previous_version_retention_days == null || try(var.previous_version_retention_days >= 1 && floor(var.previous_version_retention_days) == var.previous_version_retention_days, false)
    error_message = "previous_version_retention_days must be a whole number of at least 1, or null."
  }
}

variable "multipart_upload_abort_days" {
  description = "Abort unfinished multipart uploads after this many days; null keeps them. Needs the Object Storage service IAM policy (README)."
  type        = number
  default     = null

  validation {
    condition     = var.multipart_upload_abort_days == null || try(var.multipart_upload_abort_days >= 1 && floor(var.multipart_upload_abort_days) == var.multipart_upload_abort_days, false)
    error_message = "multipart_upload_abort_days must be a whole number of at least 1, or null."
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
