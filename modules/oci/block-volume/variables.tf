variable "name" {
  description = "Base for resource names (<name>-<resource>), for example org-workload-env-region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 50 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "qualifier" {
  description = "Role appended after the type (<name>-bv-<qualifier>), for example data; null for none."
  type        = string
  default     = null

  validation {
    condition     = var.qualifier == null || can(regex("^[a-z0-9]{1,15}$", coalesce(var.qualifier, "x")))
    error_message = "qualifier must be 1 to 15 lowercase letters or digits, or null."
  }
}

variable "volume_number" {
  description = "Volume number appended as -NN when several volumes share a name; null for none."
  type        = number
  default     = null

  validation {
    condition     = var.volume_number == null || try(var.volume_number >= 1 && var.volume_number <= 99 && floor(var.volume_number) == var.volume_number, false)
    error_message = "volume_number must be a whole number from 1 to 99, or null."
  }
}

variable "compartment_id" {
  description = "OCID of the compartment for the volume."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "availability_domain" {
  description = "Availability domain number (1 to 3); must match the instance when attached."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 3], var.availability_domain)
    error_message = "availability_domain must be 1, 2 or 3."
  }
}

variable "size_in_gbs" {
  description = "Volume size in GB (50 to 32768). Counts toward the 200 GB of OCI Always Free with boot volumes."
  type        = number
  default     = 50

  validation {
    condition     = var.size_in_gbs >= 50 && var.size_in_gbs <= 32768
    error_message = "size_in_gbs must be from 50 to 32768."
  }
}

variable "vpus_per_gb" {
  description = "Performance units per GB: 0 = lower cost, 10 = balanced, 20 = higher, 30 to 120 = ultra high."
  type        = number
  default     = 10

  validation {
    condition     = var.vpus_per_gb >= 0 && var.vpus_per_gb <= 120 && var.vpus_per_gb % 10 == 0
    error_message = "vpus_per_gb must be a multiple of 10 from 0 to 120."
  }
}

variable "kms_key_id" {
  description = "OCID of a Vault key; null uses Oracle-managed keys."
  type        = string
  default     = null
}

variable "backup_policy" {
  description = "Oracle-defined backup policy: bronze, silver, gold, or null for none. Every policy keeps more than the 5 backups of OCI Always Free."
  type        = string
  default     = null

  validation {
    condition     = var.backup_policy == null || contains(["bronze", "silver", "gold"], coalesce(var.backup_policy, "none"))
    error_message = "backup_policy must be bronze, silver, gold or null."
  }
}

variable "instance_id" {
  description = "OCID of the instance to attach the volume to; null leaves it detached."
  type        = string
  default     = null

  validation {
    condition     = var.instance_id == null || can(regex("^ocid1\\.instance\\.", coalesce(var.instance_id, "x")))
    error_message = "instance_id must be an instance OCID, or null."
  }
}

variable "attachment_type" {
  description = "paravirtualized (in-transit encryption available) or iscsi."
  type        = string
  default     = "paravirtualized"

  validation {
    condition     = contains(["paravirtualized", "iscsi"], var.attachment_type)
    error_message = "attachment_type must be paravirtualized or iscsi."
  }
}

variable "device" {
  description = "Consistent device path, for example /dev/oracleoci/oraclevdb; null lets OCI choose."
  type        = string
  default     = null

  validation {
    condition     = var.device == null || can(regex("^/dev/oracleoci/oraclevd[b-z]{1,2}$", coalesce(var.device, "x")))
    error_message = "device must look like /dev/oracleoci/oraclevdb, or null."
  }
}

variable "read_only" {
  description = "Attach the volume read-only."
  type        = bool
  default     = false
}

variable "encrypt_in_transit" {
  description = "Encrypt traffic between instance and volume (paravirtualized only; the instance must have it enabled)."
  type        = bool
  default     = true
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
