variable "name" {
  description = "Base for resource names (<name>-<resource>), for example org-workload-env-region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 50 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "qualifier" {
  description = "Role appended after the type (<name>-bdg-<qualifier>), for example lab; null for none."
  type        = string
  default     = null

  validation {
    condition     = var.qualifier == null || can(regex("^[a-z0-9]{1,15}$", coalesce(var.qualifier, "x")))
    error_message = "qualifier must be 1 to 15 lowercase letters or digits, or null."
  }
}

variable "tenancy_id" {
  description = "OCID of the tenancy (budgets are created in the root compartment)."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.tenancy\\.", var.tenancy_id))
    error_message = "tenancy_id must be a tenancy OCID."
  }
}

variable "description" {
  description = "Description of the budget."
  type        = string
  default     = "Spend budget, managed by Terraform"
}

variable "amount" {
  description = "Budget amount, a whole number in the currency of the tenancy rate card."
  type        = number

  validation {
    condition     = var.amount >= 1 && floor(var.amount) == var.amount
    error_message = "amount must be a whole number of at least 1."
  }
}

variable "target_compartment_id" {
  description = "Compartment whose spend (with children) the budget tracks; null tracks the whole tenancy. OCI allows one budget per compartment."
  type        = string
  default     = null

  validation {
    condition     = var.target_compartment_id == null || can(regex("^ocid1\\.(compartment|tenancy)\\.", coalesce(var.target_compartment_id, "x")))
    error_message = "target_compartment_id must be a compartment or tenancy OCID, or null."
  }
}

variable "target_tag" {
  description = "Cost-tracking tag to track instead of a compartment, as <namespace>.<key>.<value>. OCI allows one budget per tag."
  type        = string
  default     = null

  validation {
    condition     = var.target_tag == null || can(regex("^[^.\\s]+\\.[^.\\s]+\\.[^.\\s]+$", coalesce(var.target_tag, "x")))
    error_message = "target_tag must look like <namespace>.<key>.<value>, or null."
  }

  validation {
    condition     = var.target_tag == null || var.target_compartment_id == null
    error_message = "Set target_tag or target_compartment_id, not both."
  }
}

variable "start_day" {
  description = "Day of the month when a monthly budget period starts (fixed, so plans stay stable)."
  type        = number
  default     = 1

  validation {
    condition     = var.start_day >= 1 && var.start_day <= 31 && floor(var.start_day) == var.start_day
    error_message = "start_day must be a whole number from 1 to 31."
  }
}

variable "single_use" {
  description = "One-time budget instead of monthly: start_date and end_date as YYYY-MM-DD, at most one year apart."
  type = object({
    start_date = string
    end_date   = string
  })
  default = null

  validation {
    condition     = var.single_use == null || (can(regex("^\\d{4}-\\d{2}-\\d{2}$", try(var.single_use.start_date, ""))) && can(regex("^\\d{4}-\\d{2}-\\d{2}$", try(var.single_use.end_date, ""))))
    error_message = "single_use dates must be YYYY-MM-DD."
  }

  validation {
    condition     = var.single_use == null || try(timecmp("${var.single_use.end_date}T00:00:00Z", "${var.single_use.start_date}T00:00:00Z") > 0 && timecmp("${var.single_use.end_date}T00:00:00Z", timeadd("${var.single_use.start_date}T00:00:00Z", "8784h")) <= 0, false)
    error_message = "single_use end_date must be after start_date and at most one year later."
  }
}

variable "recipients" {
  description = "Email addresses for every alert rule that does not set its own."
  type        = list(string)

  validation {
    condition     = length(var.recipients) > 0 && alltrue([for r in var.recipients : can(regex("^[^@\\s,]+@[^@\\s,]+\\.[^@\\s,]+$", r))])
    error_message = "recipients needs at least one email address."
  }
}

variable "alert_rules" {
  description = "Alert rules keyed by short name (<name>-bdg-<key>). type ACTUAL or FORECAST; threshold_type PERCENTAGE (of amount) or ABSOLUTE (currency)."
  type = map(object({
    type           = optional(string, "ACTUAL")
    threshold_type = optional(string, "PERCENTAGE")
    threshold      = number
    recipients     = optional(list(string))
    message        = optional(string)
  }))
  default = {
    actual50    = { threshold = 50 }
    actual100   = { threshold = 100 }
    forecast100 = { type = "FORECAST", threshold = 100 }
  }

  validation {
    condition     = length(var.alert_rules) > 0 && alltrue([for k in keys(var.alert_rules) : can(regex("^[a-z0-9]{1,15}$", k))])
    error_message = "alert_rules needs at least one rule; keys are 1 to 15 lowercase letters or digits."
  }

  validation {
    condition     = alltrue([for r in values(var.alert_rules) : contains(["ACTUAL", "FORECAST"], r.type) && contains(["PERCENTAGE", "ABSOLUTE"], r.threshold_type)])
    error_message = "type must be ACTUAL or FORECAST and threshold_type PERCENTAGE or ABSOLUTE."
  }

  validation {
    condition     = alltrue([for r in values(var.alert_rules) : r.threshold > 0 && (r.threshold_type == "ABSOLUTE" || r.threshold <= 10000)])
    error_message = "threshold must be above 0, and at most 10000 for PERCENTAGE."
  }

  validation {
    condition     = alltrue([for r in values(var.alert_rules) : r.recipients == null || alltrue([for e in coalesce(r.recipients, ["x@x.x"]) : can(regex("^[^@\\s,]+@[^@\\s,]+\\.[^@\\s,]+$", e))])])
    error_message = "Rule recipients must be email addresses."
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
