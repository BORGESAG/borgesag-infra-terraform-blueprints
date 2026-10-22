variable "region" {
  description = "OCI region for the provider (budgets live in the root compartment)."
  type        = string
}

variable "tenancy_id" {
  description = "OCID of the tenancy."
  type        = string
}

variable "recipients" {
  description = "Email addresses that receive the budget alerts."
  type        = list(string)
}
