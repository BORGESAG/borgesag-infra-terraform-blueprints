variable "region" {
  description = "OCI home region (the grant policy is an IAM change)."
  type        = string
}

variable "compartment_id" {
  description = "OCID of a sandbox compartment for the vault, key and policy."
  type        = string
}
