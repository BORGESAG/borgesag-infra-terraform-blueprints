provider "oci" {
  # Credentials come from ~/.oci/config (profile DEFAULT); nothing is set here.
  region = var.region
}

module "naming" {
  source = "../../../modules/multi/naming"

  org                 = "acme"
  workload            = "app"
  environment         = "lab"
  provider_name       = "oci"
  region              = var.region
  owner               = "platform-team"
  cost_center         = "cc-0000"
  data_classification = "internal"
  criticality         = "low"
  source_path         = "borgesag-infra-terraform-blueprints/examples/oci/compute"
}

module "network" {
  source = "../../../modules/oci/network"

  name           = module.naming.prefix
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.30.0.0/16"]
  dns_label      = "examplecmp"

  subnets = {
    app = { cidr_block = "10.30.1.0/24", dns_label = "app" }
  }

  tags = module.naming.tags
}

# Always Free: one A1.Flex instance with 1 OCPU and 6 GB, private IP only, no backup policy.
module "compute" {
  source = "../../../modules/oci/compute"

  name                = module.naming.prefix
  instance_number     = 1
  compartment_id      = var.compartment_id
  subnet_id           = module.network.subnet_ids["app"]
  image_id            = var.image_id
  ssh_authorized_keys = var.ssh_authorized_keys

  tags = module.naming.tags
}
