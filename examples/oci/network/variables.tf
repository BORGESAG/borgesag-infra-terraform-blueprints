variable "region" {
  description = "OCI region, for example sa-saopaulo-1."
  type        = string
}

variable "compartment_id" {
  description = "OCID of a sandbox compartment."
  type        = string
}

variable "name" {
  description = "Base for resource names."
  type        = string
  default     = "example-net-lab"
}
