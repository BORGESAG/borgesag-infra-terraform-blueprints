variable "org" {
  description = "Short organization code, 2 to 10 lowercase letters or digits."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.org))
    error_message = "org must be 2 to 10 lowercase letters or digits, starting with a letter."
  }
}

variable "workload" {
  description = "Workload or application code, 2 to 15 lowercase letters or digits."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,14}$", var.workload))
    error_message = "workload must be 2 to 15 lowercase letters or digits, starting with a letter."
  }
}

variable "environment" {
  description = "Environment code: dev, tst, stg, prd, lab or sbx."
  type        = string

  validation {
    condition     = contains(["dev", "tst", "stg", "prd", "lab", "sbx"], var.environment)
    error_message = "environment must be one of dev, tst, stg, prd, lab, sbx."
  }
}

variable "provider_name" {
  description = "Target provider: aws, azure, gcp, oci or proxmox."
  type        = string

  validation {
    condition     = contains(["aws", "azure", "gcp", "oci", "proxmox"], var.provider_name)
    error_message = "provider_name must be one of aws, azure, gcp, oci, proxmox."
  }
}

variable "region" {
  description = "Provider region identifier, for example sa-saopaulo-1."
  type        = string
}

variable "region_code" {
  description = "Short region code (2 to 4 lowercase letters or digits). Required when the region is not in the built-in table (OCI region keys)."
  type        = string
  default     = null

  validation {
    condition     = var.region_code == null || can(regex("^[a-z0-9]{2,4}$", var.region_code))
    error_message = "region_code must be 2 to 4 lowercase letters or digits."
  }
}

variable "owner" {
  description = "Team or person accountable for the resources."
  type        = string
}

variable "cost_center" {
  description = "Cost center used for chargeback and cost reports."
  type        = string
}

variable "data_classification" {
  description = "Highest classification of data handled: public, internal or confidential."
  type        = string

  validation {
    condition     = contains(["public", "internal", "confidential"], var.data_classification)
    error_message = "data_classification must be public, internal or confidential."
  }
}

variable "criticality" {
  description = "Business criticality: low, medium or high."
  type        = string

  validation {
    condition     = contains(["low", "medium", "high"], var.criticality)
    error_message = "criticality must be low, medium or high."
  }
}

variable "source_path" {
  description = "Repository and path of the root module, for traceability (tag source)."
  type        = string
}

variable "extra_tags" {
  description = "Additional tags; cannot override the standard keys."
  type        = map(string)
  default     = {}
}
