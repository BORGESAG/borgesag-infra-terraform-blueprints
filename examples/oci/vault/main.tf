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
  source_path         = "borgesag-infra-terraform-blueprints/examples/oci/vault"
}

# A shared-partition vault with one HSM AES-256 key (1 of the 20 Always Free HSM key
# versions) that Object Storage and Block Volume may use for buckets and volumes.
module "vault" {
  source = "../../../modules/oci/vault"

  name           = module.naming.prefix
  compartment_id = var.compartment_id

  keys = {
    data = {
      service_grantees = ["objectstorage-${var.region}", "blockstorage"]
    }
  }

  tags = module.naming.tags
}
