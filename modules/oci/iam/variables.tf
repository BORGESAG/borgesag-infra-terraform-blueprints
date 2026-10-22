variable "name" {
  description = "Base for resource names (<name>-<resource>), for example org-workload-env-region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 50 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "tenancy_id" {
  description = "OCID of the tenancy (dynamic groups live at the root)."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.tenancy\\.", var.tenancy_id))
    error_message = "tenancy_id must be a tenancy OCID."
  }
}

variable "compartment_id" {
  description = "OCID of an existing workload compartment; null creates <name>-cmp under parent_compartment_id."
  type        = string
  default     = null

  validation {
    condition     = var.compartment_id == null || can(regex("^ocid1\\.compartment\\.", coalesce(var.compartment_id, "x")))
    error_message = "compartment_id must be a compartment OCID, or null."
  }
}

variable "parent_compartment_id" {
  description = "Parent of the created compartment; null uses the tenancy root."
  type        = string
  default     = null

  validation {
    condition     = var.parent_compartment_id == null || can(regex("^ocid1\\.(compartment|tenancy)\\.", coalesce(var.parent_compartment_id, "x")))
    error_message = "parent_compartment_id must be a compartment or tenancy OCID, or null."
  }
}

variable "compartment_description" {
  description = "Description of the created compartment."
  type        = string
  default     = "Workload compartment, managed by Terraform"
}

variable "compartment_enable_delete" {
  description = "Delete the compartment on destroy. False only removes it from state (deletion protection)."
  type        = bool
  default     = false
}

variable "dynamic_groups" {
  description = "Dynamic groups keyed by role (<name>-dg-<key>). {compartment_id} in matching_rule is replaced by the workload compartment OCID."
  type = map(object({
    description   = string
    matching_rule = string
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.dynamic_groups) : can(regex("^[a-z0-9]{1,15}$", k))])
    error_message = "dynamic_groups keys must be 1 to 15 lowercase letters or digits."
  }
}

variable "policies" {
  description = "Policies keyed by role (<name>-pol-<key>), attached to the workload compartment unless compartment_id is set. {compartment_id} in statements is replaced by the workload compartment OCID."
  type = map(object({
    description    = string
    statements     = list(string)
    compartment_id = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.policies) : can(regex("^[a-z0-9]{1,15}$", k))])
    error_message = "policies keys must be 1 to 15 lowercase letters or digits."
  }

  validation {
    condition     = !contains(keys(var.policies), "objectstorage")
    error_message = "policies key objectstorage is reserved for object_storage_service_policy."
  }

  validation {
    condition     = alltrue([for p in values(var.policies) : length(p.statements) > 0])
    error_message = "Every policy needs at least one statement."
  }

  # Same rule as the upstream CIS IAM 1.2 check, raised at plan time.
  validation {
    condition     = !var.enable_cis_checks || alltrue(flatten([for p in values(var.policies) : [for s in p.statements : !can(regex(".*to\\s*manage\\s*all-resources\\s*in\\s*tenancy\\s*$", lower(s)))]]))
    error_message = "CIS IAM 1.2: no statement may manage all-resources in tenancy (set enable_cis_checks = false to override)."
  }
}

variable "object_storage_service_policy" {
  description = "Allow the Object Storage service to manage objects in the workload compartment (lifecycle rules of oci/object-storage). Needs region."
  type        = bool
  default     = false

  validation {
    condition     = !var.object_storage_service_policy || var.region != null
    error_message = "object_storage_service_policy needs region (for example sa-saopaulo-1)."
  }
}

variable "region" {
  description = "Region identifier for service policies, for example sa-saopaulo-1."
  type        = string
  default     = null

  validation {
    condition     = var.region == null || can(regex("^[a-z]{2,}-[a-z]+-[0-9]$", coalesce(var.region, "x")))
    error_message = "region must look like sa-saopaulo-1, or null."
  }
}

variable "enable_cis_checks" {
  description = "Upstream CIS IAM checks: reject manage all-resources in tenancy and changes to the Administrators group."
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
