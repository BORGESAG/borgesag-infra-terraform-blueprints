variable "name" {
  description = "Base for resource names (<name>-<resource>), for example org-workload-env-region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.name)) && !can(regex("^(oci|orcl)", var.name))
    error_message = "name must be 3 to 50 characters: lowercase letters, digits and hyphens, starting with a letter and not with oci or orcl (reserved by OCI)."
  }
}

variable "tenancy_id" {
  description = "OCID of the tenancy."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.tenancy\\.", var.tenancy_id))
    error_message = "tenancy_id must be a tenancy OCID."
  }
}

variable "compartment_id" {
  description = "Compartment that holds the tag namespace; null uses the tenancy root. Tag keys can be applied anywhere in the tenancy."
  type        = string
  default     = null

  validation {
    condition     = var.compartment_id == null || can(regex("^ocid1\\.(compartment|tenancy)\\.", coalesce(var.compartment_id, "x")))
    error_message = "compartment_id must be a compartment or tenancy OCID, or null."
  }
}

variable "description" {
  description = "Description of the tag namespace."
  type        = string
  default     = "Defined tags, managed by Terraform"
}

variable "tag_definitions" {
  description = "Tag keys in the namespace (<name>-tns.<key>). values restricts the key to a list; default sets a tag default in the given compartments."
  type = map(object({
    description   = string
    cost_tracking = optional(bool, false)
    values        = optional(list(string))
    retired       = optional(bool, false)
    default = optional(object({
      value           = string
      compartment_ids = list(string)
      required        = optional(bool, false)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.tag_definitions) : can(regex("^[a-z][a-z0-9-]{0,62}$", k)) && !can(regex("^(oci|orcl)", k))])
    error_message = "tag_definitions keys must be 1 to 63 lowercase letters, digits or hyphens, starting with a letter and not with oci or orcl."
  }

  validation {
    condition     = alltrue([for v in values(var.tag_definitions) : v.values == null || (length(coalesce(v.values, ["x"])) > 0 && length(coalesce(v.values, ["x"])) <= 100)])
    error_message = "values needs 1 to 100 entries (OCI limit per tag key), or null for free text."
  }

  # Variables such as $${iam.principal.name} are resolved by OCI and cannot be checked here.
  validation {
    condition     = alltrue([for v in values(var.tag_definitions) : v.default == null || v.values == null || startswith(try(v.default.value, ""), "$${") || contains(coalesce(v.values, []), try(v.default.value, ""))])
    error_message = "A tag default value must be one of the tag key values."
  }

  # OCI allows 10 cost-tracking tags per tenancy, counting retired ones; other namespaces use some.
  validation {
    condition     = length([for v in values(var.tag_definitions) : v if v.cost_tracking]) <= 10
    error_message = "At most 10 cost-tracking tags per tenancy."
  }

  validation {
    condition     = alltrue([for v in values(var.tag_definitions) : v.default == null || alltrue([for c in try(v.default.compartment_ids, []) : can(regex("^ocid1\\.(compartment|tenancy)\\.", c))])])
    error_message = "Tag default compartment_ids must be compartment or tenancy OCIDs."
  }

  # A required default at the root blocks every resource created without the tag in the tenancy.
  validation {
    condition     = alltrue([for v in values(var.tag_definitions) : v.default == null || !try(v.default.required, false) || !contains(try(v.default.compartment_ids, []), var.tenancy_id)])
    error_message = "A required tag default cannot target the tenancy root; scope it to workload compartments."
  }
}

variable "retired" {
  description = "Retire the namespace and all its keys. OCI deletes only retired namespaces: set true and apply before terraform destroy."
  type        = bool
  default     = false
}

variable "cis_created_tags" {
  description = "Create the CIS CreatedBy and CreatedOn tags with tenancy-wide defaults in <name>-cis-tns, only when the tenancy has no Oracle-Tags namespace."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Freeform tags, merged with managed-by=terraform."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value) for the namespace and its keys."
  type        = map(string)
  default     = null
}
