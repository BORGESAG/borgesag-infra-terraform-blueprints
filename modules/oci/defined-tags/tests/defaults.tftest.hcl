mock_provider "oci" {
  # No Oracle-Tags namespace, so the upstream CIS branch can be exercised.
  mock_data "oci_identity_tag_namespaces" {
    defaults = {
      tag_namespaces = []
    }
  }
}

variables {
  name       = "example-gov-dev"
  tenancy_id = "ocid1.tenancy.oc1..exampleuniqueid"
  tags       = { environment = "dev" }
}

run "namespace_with_keys_and_default" {
  command = apply

  variables {
    tag_definitions = {
      cost-center = {
        description   = "Cost center code"
        cost_tracking = true
        default = {
          value           = "cc-0000"
          compartment_ids = ["ocid1.compartment.oc1..exampleworkload"]
          required        = true
        }
      }
      environment = {
        description = "Environment of the resource"
        values      = ["dev", "prd"]
      }
    }
  }

  assert {
    condition     = module.tags.tag_namespaces["workload"].name == "example-gov-dev-tns" && module.tags.tag_namespaces["workload"].compartment_id == var.tenancy_id
    error_message = "The namespace must be <name>-tns in the tenancy root by default."
  }

  assert {
    condition     = module.tags.tag_namespaces["workload"].freeform_tags["managed-by"] == "terraform" && module.tags.tag_namespaces["workload"].freeform_tags["iac-module"] == "oci/defined-tags" && module.tags.tag_namespaces["workload"].freeform_tags["environment"] == "dev"
    error_message = "Tags must merge the input with managed-by and iac-module."
  }

  assert {
    condition     = module.tags.tags["cost-center"].is_cost_tracking && !module.tags.tags["environment"].is_cost_tracking && !module.tags.tags["cost-center"].is_retired
    error_message = "cost_tracking must map to the tag key; keys start active."
  }

  assert {
    condition     = module.tags.tags["environment"].validator[0].validator_type == "ENUM" && module.tags.tags["environment"].validator[0].values == tolist(["dev", "prd"]) && length(module.tags.tags["cost-center"].validator) == 0
    error_message = "values must become an ENUM validator, and free-text keys have none."
  }

  assert {
    condition     = module.tags.tag_defaults["cost-center.ocid1.compartment.oc1..exampleworkload"].compartment_id == "ocid1.compartment.oc1..exampleworkload" && module.tags.tag_defaults["cost-center.ocid1.compartment.oc1..exampleworkload"].value == "cc-0000" && module.tags.tag_defaults["cost-center.ocid1.compartment.oc1..exampleworkload"].is_required
    error_message = "The tag default must target the given compartment with its value and required flag."
  }

  assert {
    condition     = output.defined_tag_keys["cost-center"] == "example-gov-dev-tns.cost-center" && length(output.tag_default_ids) == 1 && length(module.tags.tag_namespaces) == 1
    error_message = "Outputs must give <namespace>.<key>; no CIS namespace by default."
  }
}

run "namespace_in_compartment_with_shared_default_compartment" {
  command = apply

  variables {
    compartment_id = "ocid1.compartment.oc1..examplegovernance"
    tag_definitions = {
      owner = {
        description = "Accountable team"
        default     = { value = "platform-team", compartment_ids = ["ocid1.compartment.oc1..exampleworkload"] }
      }
      criticality = {
        description = "Business criticality"
        values      = ["low", "medium", "high"]
        default     = { value = "low", compartment_ids = ["ocid1.compartment.oc1..exampleworkload"] }
      }
    }
  }

  assert {
    condition     = module.tags.tag_namespaces["workload"].compartment_id == "ocid1.compartment.oc1..examplegovernance"
    error_message = "compartment_id must hold the namespace."
  }

  assert {
    condition     = length(module.tags.tag_defaults) == 2 && !module.tags.tag_defaults["owner.ocid1.compartment.oc1..exampleworkload"].is_required
    error_message = "Two keys may default in the same compartment; defaults are optional unless required."
  }
}

run "retired_retires_keys" {
  command = apply

  variables {
    retired         = true
    tag_definitions = { owner = { description = "Accountable team" } }
  }

  assert {
    condition     = module.tags.tag_namespaces["workload"].is_retired && module.tags.tags["owner"].is_retired
    error_message = "retired must retire the namespace and its keys."
  }
}

run "cis_created_tags" {
  command = apply

  variables {
    cis_created_tags = true
  }

  assert {
    condition     = module.tags.tag_namespaces["CIS-NAMESPACE"].name == "example-gov-dev-cis-tns" && module.tags.tags["CIS-CREATED-BY-TAG"].name == "CreatedBy" && module.tags.tags["CIS-CREATED-ON-TAG"].name == "CreatedOn"
    error_message = "cis_created_tags must create the CIS namespace with CreatedBy and CreatedOn when Oracle-Tags is absent."
  }

  assert {
    condition     = length(output.tag_default_ids) == 0
    error_message = "CIS defaults must stay out of tag_default_ids."
  }
}

run "rejects_bad_key" {
  command = plan

  variables {
    tag_definitions = { CostCenter = { description = "x" } }
  }

  expect_failures = [var.tag_definitions]
}

run "rejects_reserved_key" {
  command = plan

  variables {
    tag_definitions = { oci-owner = { description = "x" } }
  }

  expect_failures = [var.tag_definitions]
}

run "rejects_default_outside_values" {
  command = plan

  variables {
    tag_definitions = {
      environment = {
        description = "x"
        values      = ["dev", "prd"]
        default     = { value = "qa", compartment_ids = ["ocid1.compartment.oc1..exampleworkload"] }
      }
    }
  }

  expect_failures = [var.tag_definitions]
}

run "rejects_required_default_at_root" {
  command = plan

  variables {
    tag_definitions = {
      owner = {
        description = "x"
        default     = { value = "platform-team", compartment_ids = ["ocid1.tenancy.oc1..exampleuniqueid"], required = true }
      }
    }
  }

  expect_failures = [var.tag_definitions]
}

run "rejects_too_many_cost_tracking_tags" {
  command = plan

  variables {
    tag_definitions = { for i in range(11) : "cc${i}" => { description = "x", cost_tracking = true } }
  }

  expect_failures = [var.tag_definitions]
}

run "rejects_bad_tenancy" {
  command = plan

  variables {
    tenancy_id = "ocid1.compartment.oc1..notatenancy"
  }

  expect_failures = [var.tenancy_id]
}
