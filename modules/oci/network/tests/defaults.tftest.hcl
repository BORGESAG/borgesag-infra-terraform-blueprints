mock_provider "oci" {
  # The upstream module resolves "all-services" from this data source.
  mock_data "oci_core_services" {
    defaults = {
      services = [{
        id          = "ocid1.service.oc1.example.allservices"
        name        = "All EXAMPLE Services In Oracle Services Network"
        cidr_block  = "all-example-services-in-oracle-services-network"
        description = "Fictitious service for mocked tests"
      }]
    }
  }
}

variables {
  name           = "example-lab-dev"
  compartment_id = "ocid1.compartment.oc1..exampleuniqueid"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "examplelab"
  subnets = {
    app = { cidr_block = "10.0.1.0/24" }
  }
  tags = { environment = "dev" }
}

run "private_by_default" {
  command = apply

  assert {
    condition     = local.network_configuration.network_configuration_categories["example-lab-dev"].vcns["vcn"].display_name == "example-lab-dev-vcn"
    error_message = "The VCN name must follow <name>-<resource>."
  }

  assert {
    condition     = local.subnets["app"].display_name == "example-lab-dev-app-subnet"
    error_message = "The subnet name must follow <name>-<key>-subnet."
  }

  assert {
    condition     = local.subnets["app"].prohibit_public_ip_on_vnic && local.subnets["app"].prohibit_internet_ingress
    error_message = "Subnets must be private unless public = true."
  }

  assert {
    condition     = local.subnets["app"].route_table_key == "rt-private"
    error_message = "Private subnets must use the private route table."
  }

  assert {
    condition     = keys(local.route_tables) == ["rt-private"] && length(local.private_route_rules) == 0
    error_message = "Without gateways there must be one private route table with no routes."
  }

  assert {
    condition     = length(local.network_configuration.network_configuration_categories["example-lab-dev"].vcns["vcn"].default_security_list.ingress_rules) == 0
    error_message = "The default security list must have no ingress rules."
  }

  assert {
    condition     = local.tags["managed-by"] == "terraform" && local.tags["environment"] == "dev"
    error_message = "Tags must merge the input with managed-by=terraform."
  }

  assert {
    condition     = output.internet_gateway_id == null && output.nat_gateway_id == null && output.service_gateway_id == null
    error_message = "No gateway is created by default."
  }

  assert {
    condition     = length(output.subnet_ids) == 1 && output.vcn_id != null
    error_message = "The VCN and the subnet must be created."
  }
}

run "public_subnet_with_gateways" {
  command = apply

  variables {
    subnets = {
      web = { cidr_block = "10.0.0.0/24", public = true }
      app = { cidr_block = "10.0.1.0/24" }
    }
    create_internet_gateway = true
    create_nat_gateway      = true
    create_service_gateway  = true
  }

  assert {
    condition     = !local.subnets["web"].prohibit_public_ip_on_vnic && local.subnets["web"].route_table_key == "rt-public"
    error_message = "A public subnet must allow public IPs and use the public route table."
  }

  assert {
    condition     = local.public_route_rules["internet"].network_entity_id == "igw"
    error_message = "The public route table must route 0.0.0.0/0 to the internet gateway."
  }

  assert {
    condition     = toset(keys(local.private_route_rules)) == toset(["nat", "services"])
    error_message = "The private route table must route through the NAT and service gateways."
  }

  assert {
    condition     = output.internet_gateway_id != null && output.nat_gateway_id != null && output.service_gateway_id != null
    error_message = "All requested gateways must be created."
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    name = "Bad_Name"
  }

  expect_failures = [var.name]
}

run "rejects_bad_cidr" {
  command = plan

  variables {
    cidr_blocks = ["10.0.0.0/33"]
  }

  expect_failures = [var.cidr_blocks]
}

run "rejects_public_subnet_without_internet_gateway" {
  command = plan

  variables {
    subnets = {
      web = { cidr_block = "10.0.0.0/24", public = true }
    }
  }

  expect_failures = [var.subnets]
}
