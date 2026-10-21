variable "name" {
  description = "Base for resource names (<name>-<resource>), for example org-workload-env-region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 50 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "compartment_id" {
  description = "OCID of the compartment for every resource of the module."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "cidr_blocks" {
  description = "IPv4 CIDR blocks of the VCN."
  type        = list(string)

  validation {
    condition     = length(var.cidr_blocks) > 0 && alltrue([for c in var.cidr_blocks : can(cidrhost(c, 0))])
    error_message = "cidr_blocks must hold at least one valid IPv4 CIDR."
  }
}

variable "dns_label" {
  description = "DNS label of the VCN; null disables VCN DNS hostnames."
  type        = string
  default     = null

  validation {
    condition     = var.dns_label == null || can(regex("^[a-z][a-z0-9]{0,14}$", var.dns_label))
    error_message = "dns_label must be 1 to 15 lowercase letters or digits, starting with a letter."
  }
}

variable "subnets" {
  description = "Subnets keyed by short name. Private by default; public subnets need create_internet_gateway."
  type = map(object({
    cidr_block = string
    public     = optional(bool, false)
    dns_label  = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for s in values(var.subnets) : can(cidrhost(s.cidr_block, 0))])
    error_message = "Every subnet cidr_block must be a valid IPv4 CIDR."
  }

  validation {
    condition     = alltrue([for s in values(var.subnets) : s.dns_label == null || can(regex("^[a-z][a-z0-9]{0,14}$", s.dns_label))])
    error_message = "Subnet dns_label must be 1 to 15 lowercase letters or digits, starting with a letter."
  }

  validation {
    condition     = var.create_internet_gateway || !anytrue([for s in values(var.subnets) : s.public])
    error_message = "A public subnet needs create_internet_gateway = true."
  }
}

variable "create_internet_gateway" {
  description = "Create an internet gateway and the public route table."
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Create a NAT gateway for private subnets. Not part of OCI Always Free."
  type        = bool
  default     = false
}

variable "create_service_gateway" {
  description = "Create a service gateway to all OCI services. Not part of OCI Always Free."
  type        = bool
  default     = false
}

variable "enable_cis_checks" {
  description = "Let the upstream module reject configurations that break CIS OCI Foundations network recommendations."
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
