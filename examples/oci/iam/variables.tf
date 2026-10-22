variable "region" {
  description = "OCI home region (IAM changes are made in the home region)."
  type        = string
}

variable "tenancy_id" {
  description = "OCID of the tenancy."
  type        = string
}

variable "parent_compartment_id" {
  description = "OCID of a sandbox compartment that receives the new workload compartment."
  type        = string
}
