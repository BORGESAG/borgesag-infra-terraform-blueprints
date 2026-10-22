variable "region" {
  description = "OCI home region (tag namespaces are created in the home region)."
  type        = string
}

variable "tenancy_id" {
  description = "OCID of the tenancy."
  type        = string
}

variable "compartment_id" {
  description = "OCID of a sandbox compartment that holds the namespace and receives the tag defaults."
  type        = string
}
