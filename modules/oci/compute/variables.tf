variable "name" {
  description = "Base for resource names (<name>-<resource>), for example org-workload-env-region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 50 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "instance_number" {
  description = "Instance number appended as -NN when several instances share a name; null for none."
  type        = number
  default     = null

  validation {
    condition     = var.instance_number == null || try(var.instance_number >= 1 && var.instance_number <= 99 && floor(var.instance_number) == var.instance_number, false)
    error_message = "instance_number must be a whole number from 1 to 99, or null."
  }
}

variable "compartment_id" {
  description = "OCID of the compartment for the instance."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "subnet_id" {
  description = "OCID of the subnet for the primary VNIC."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.subnet\\.", var.subnet_id))
    error_message = "subnet_id must be a subnet OCID."
  }
}

variable "image_id" {
  description = "OCID of the image (platform or custom). List with: oci compute image list --compartment-id <id> --shape <shape>."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.image\\.", var.image_id))
    error_message = "image_id must be an image OCID."
  }
}

variable "availability_domain" {
  description = "Availability domain number in the region (1 to 3)."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 3], var.availability_domain)
    error_message = "availability_domain must be 1, 2 or 3."
  }
}

variable "fault_domain" {
  description = "Fault domain number (1 to 3); null lets OCI choose."
  type        = number
  default     = null

  validation {
    condition     = var.fault_domain == null || contains([1, 2, 3], var.fault_domain)
    error_message = "fault_domain must be 1, 2, 3 or null."
  }
}

variable "shape" {
  description = "Instance shape. VM.Standard.A1.Flex and VM.Standard.E2.1.Micro are OCI Always Free."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "OCPUs for Flex shapes; ignored otherwise."
  type        = number
  default     = 1

  validation {
    condition     = var.ocpus > 0
    error_message = "ocpus must be greater than 0."
  }
}

variable "memory_in_gbs" {
  description = "Memory in GB for Flex shapes; ignored otherwise."
  type        = number
  default     = 6

  validation {
    condition     = var.memory_in_gbs > 0
    error_message = "memory_in_gbs must be greater than 0."
  }
}

variable "ssh_authorized_keys" {
  description = "Public SSH keys, one per line; null for no key (console or OS Login only)."
  type        = string
  default     = null

  validation {
    condition     = var.ssh_authorized_keys == null || can(regex("^(ssh-(ed25519|rsa)|ecdsa-sha2-nistp(256|384|521)) ", var.ssh_authorized_keys))
    error_message = "ssh_authorized_keys must start with ssh-ed25519, ssh-rsa or ecdsa-sha2-nistp*."
  }
}

variable "user_data" {
  description = "cloud-init content in plain text; encoded by the module. Never put secrets here."
  type        = string
  default     = null
}

variable "assign_public_ip" {
  description = "Assign a public IP to the primary VNIC. The subnet must be public."
  type        = bool
  default     = false
}

variable "nsg_ids" {
  description = "Network security group OCIDs for the primary VNIC."
  type        = list(string)
  default     = []
}

variable "hostname_label" {
  description = "Hostname in the subnet DNS; null derives it from the display name."
  type        = string
  default     = null
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB (OCI minimum 50)."
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50
    error_message = "boot_volume_size_in_gbs must be at least 50."
  }
}

variable "boot_volume_vpus_per_gb" {
  description = "Boot volume performance units per GB (10 = balanced)."
  type        = number
  default     = 10
}

variable "kms_key_id" {
  description = "OCID of a Vault key for the boot volume; null uses Oracle-managed keys."
  type        = string
  default     = null
}

variable "encrypt_in_transit" {
  description = "Encrypt paravirtualized volume traffic between instance and storage."
  type        = bool
  default     = true
}

variable "backup_policy" {
  description = "Oracle-defined boot volume backup policy: bronze, silver, gold, or null for none. Every policy keeps more than the 5 backups of OCI Always Free."
  type        = string
  default     = null

  validation {
    condition     = var.backup_policy == null || contains(["bronze", "silver", "gold"], coalesce(var.backup_policy, "none"))
    error_message = "backup_policy must be bronze, silver, gold or null."
  }
}

variable "preserve_boot_volume" {
  description = "Keep the boot volume when the instance is destroyed."
  type        = bool
  default     = false
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
