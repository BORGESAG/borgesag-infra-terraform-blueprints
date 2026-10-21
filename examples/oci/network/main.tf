provider "oci" {
  # Credentials come from ~/.oci/config (profile DEFAULT); nothing is set here.
  region = var.region
}

module "network" {
  source = "../../../modules/oci/network"

  name           = var.name
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.20.0.0/16"]
  dns_label      = "examplevcn"

  subnets = {
    public = { cidr_block = "10.20.0.0/24", public = true, dns_label = "public" }
    app    = { cidr_block = "10.20.1.0/24", dns_label = "app" }
  }

  # Always Free: internet gateway only; NAT and service gateways stay off.
  create_internet_gateway = true

  tags = {
    owner       = "platform-team"
    environment = "lab"
    workload    = "example"
    source      = "borgesag-infra-terraform-blueprints/examples/oci/network"
  }
}
