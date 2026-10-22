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
  source_path         = "borgesag-infra-terraform-blueprints/examples/oci/storage"
}

module "network" {
  source = "../../../modules/oci/network"

  name           = module.naming.prefix
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.40.0.0/16"]
  dns_label      = "examplestg"

  subnets = {
    app = { cidr_block = "10.40.1.0/24", dns_label = "app" }
  }

  tags = module.naming.tags
}

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

# Always Free: 50 GB boot + 50 GB data = 100 of the 200 GB; no backup policy.
module "data_volume" {
  source = "../../../modules/oci/block-volume"

  name           = module.naming.prefix
  qualifier      = "data"
  compartment_id = var.compartment_id
  instance_id    = module.compute.instance_id
  device         = "/dev/oracleoci/oraclevdb"

  tags = module.naming.tags
}

# Always Free: 20 GB of Object Storage in total. Lifecycle rules are off here because they
# need the Object Storage service IAM policy (see the module README).
module "bucket" {
  source = "../../../modules/oci/object-storage"

  name           = module.naming.prefix
  qualifier      = "data"
  compartment_id = var.compartment_id

  tags = module.naming.tags
}
