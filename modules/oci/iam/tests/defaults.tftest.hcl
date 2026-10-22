mock_provider "oci" {
  # The upstream policies module treats a compartment_id that does not start with ocid1 as a key.
  mock_resource "oci_identity_compartment" {
    defaults = {
      id = "ocid1.compartment.oc1..examplecreated"
    }
  }

  # The upstream policies module reads the realm (oc1) from the tenancy OCID.
  mock_data "oci_identity_tenancy" {
    defaults = {
      id = "ocid1.tenancy.oc1..exampleuniqueid"
    }
  }
}

variables {
  name       = "example-app-dev"
  tenancy_id = "ocid1.tenancy.oc1..exampleuniqueid"
  tags       = { environment = "dev" }
}

run "creates_protected_compartment" {
  command = apply

  assert {
    condition     = module.compartment[0].compartments["workload"].name == "example-app-dev-cmp"
    error_message = "The compartment name must follow <name>-cmp."
  }

  assert {
    condition     = !module.compartment[0].compartments["workload"].enable_delete
    error_message = "Compartments must not be deleted on destroy by default."
  }

  assert {
    condition     = module.compartment[0].compartments["workload"].compartment_id == var.tenancy_id
    error_message = "The tenancy root must be the default parent."
  }

  assert {
    condition     = module.compartment[0].compartments["workload"].freeform_tags["managed-by"] == "terraform" && module.compartment[0].compartments["workload"].freeform_tags["iac-module"] == "oci/iam" && module.compartment[0].compartments["workload"].freeform_tags["environment"] == "dev"
    error_message = "Tags must merge the input with managed-by and iac-module."
  }

  assert {
    condition     = output.compartment_id == "ocid1.compartment.oc1..examplecreated" && length(module.dynamic_groups) == 0 && length(module.policies) == 0
    error_message = "Only the compartment is created by default."
  }
}

run "policies_in_created_compartment" {
  command = apply

  variables {
    parent_compartment_id = "ocid1.compartment.oc1..exampleparent"
    policies = {
      ops = {
        description = "Operators manage instances"
        statements  = ["Allow group example-ops to manage instance-family in compartment id {compartment_id}"]
      }
    }
  }

  assert {
    condition     = module.compartment[0].compartments["workload"].compartment_id == "ocid1.compartment.oc1..exampleparent"
    error_message = "parent_compartment_id must be the parent."
  }

  assert {
    condition     = module.policies[0].policies["ops"].name == "example-app-dev-pol-ops" && module.policies[0].policies["ops"].compartment_id == "ocid1.compartment.oc1..examplecreated"
    error_message = "Policies must follow <name>-pol-<key> in the workload compartment."
  }

  assert {
    condition     = module.policies[0].policies["ops"].statements[0] == "Allow group example-ops to manage instance-family in compartment id ocid1.compartment.oc1..examplecreated"
    error_message = "{compartment_id} must be replaced in statements."
  }
}

run "existing_compartment_with_dynamic_group" {
  command = apply

  variables {
    compartment_id                = "ocid1.compartment.oc1..exampleexisting"
    region                        = "sa-saopaulo-1"
    object_storage_service_policy = true
    dynamic_groups = {
      app = {
        description   = "Instances of the workload"
        matching_rule = "ALL {instance.compartment.id = '{compartment_id}'}"
      }
    }
  }

  assert {
    condition     = length(module.compartment) == 0 && output.compartment_id == "ocid1.compartment.oc1..exampleexisting" && output.compartment_name == null
    error_message = "An existing compartment must be used without creating one."
  }

  assert {
    condition     = module.dynamic_groups[0].dynamic_groups["app"].name == "example-app-dev-dg-app" && module.dynamic_groups[0].dynamic_groups["app"].matching_rule == "ALL {instance.compartment.id = 'ocid1.compartment.oc1..exampleexisting'}"
    error_message = "Dynamic groups must follow <name>-dg-<key> with {compartment_id} replaced."
  }

  assert {
    condition     = module.dynamic_groups[0].dynamic_groups["app"].compartment_id == var.tenancy_id
    error_message = "Dynamic groups must live in the tenancy root."
  }

  assert {
    condition     = module.policies[0].policies["objectstorage"].statements[0] == "Allow service objectstorage-sa-saopaulo-1 to manage object-family in compartment id ocid1.compartment.oc1..exampleexisting"
    error_message = "The Object Storage service policy must target the workload compartment in the given region."
  }
}

run "rejects_service_policy_without_region" {
  command = plan

  variables {
    object_storage_service_policy = true
  }

  expect_failures = [var.object_storage_service_policy]
}

run "rejects_reserved_policy_key" {
  command = plan

  variables {
    policies = {
      objectstorage = { description = "x", statements = ["Allow group a to read buckets in compartment id {compartment_id}"] }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_tenancy_admin_statement" {
  command = plan

  variables {
    policies = {
      admin = { description = "x", statements = ["Allow group example-ops to manage all-resources in tenancy"] }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_bad_dynamic_group_key" {
  command = plan

  variables {
    dynamic_groups = {
      App_Servers = { description = "x", matching_rule = "ALL {instance.compartment.id = '{compartment_id}'}" }
    }
  }

  expect_failures = [var.dynamic_groups]
}

run "rejects_bad_tenancy" {
  command = plan

  variables {
    tenancy_id = "ocid1.compartment.oc1..notatenancy"
  }

  expect_failures = [var.tenancy_id]
}
