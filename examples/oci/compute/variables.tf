variable "region" {
  description = "OCI region (the tenancy home region for Always Free)."
  type        = string
}

variable "compartment_id" {
  description = "OCID of a sandbox compartment."
  type        = string
}

variable "image_id" {
  description = "OCID of an aarch64 platform image for VM.Standard.A1.Flex in the region."
  type        = string
}

variable "ssh_authorized_keys" {
  description = "Public SSH key."
  type        = string
}
