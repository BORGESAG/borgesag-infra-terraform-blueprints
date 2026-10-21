variables {
  org                 = "acme"
  workload            = "web"
  environment         = "dev"
  provider_name       = "oci"
  region              = "sa-saopaulo-1"
  owner               = "platform-team"
  cost_center         = "cc-1001"
  data_classification = "internal"
  criticality         = "medium"
  source_path         = "example-repo/envs/dev"
}

run "oci_region_key_and_standard_tags" {
  command = plan

  assert {
    condition     = output.prefix == "acme-web-dev-gru"
    error_message = "The prefix must be <org>-<workload>-<env>-<region key>."
  }

  assert {
    condition     = output.abbreviations["subnet"] == "snet" && output.abbreviations["instance"] == "vm"
    error_message = "Abbreviations must follow ADR 0004."
  }

  assert {
    condition = output.tags == {
      "owner"               = "platform-team"
      "workload"            = "web"
      "environment"         = "dev"
      "cost-center"         = "cc-1001"
      "data-classification" = "internal"
      "criticality"         = "medium"
      "source"              = "example-repo/envs/dev"
      "managed-by"          = "terraform"
    }
    error_message = "Tags must hold exactly the standard keys."
  }
}

run "extra_tags_cannot_override_standard_keys" {
  command = plan

  variables {
    extra_tags = { "project" = "alpha", "environment" = "prd" }
  }

  assert {
    condition     = output.tags["project"] == "alpha" && output.tags["environment"] == "dev"
    error_message = "Extra tags are added but never override standard keys."
  }
}

run "explicit_region_code_for_other_providers" {
  command = plan

  variables {
    provider_name = "aws"
    region        = "sa-east-1"
    region_code   = "sae1"
  }

  assert {
    condition     = output.prefix == "acme-web-dev-sae1"
    error_message = "region_code must be used when given."
  }
}

run "rejects_unknown_region_without_code" {
  command = plan

  variables {
    provider_name = "aws"
    region        = "sa-east-1"
  }

  expect_failures = [output.prefix]
}

run "rejects_bad_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}

run "rejects_bad_classification" {
  command = plan

  variables {
    data_classification = "secret"
  }

  expect_failures = [var.data_classification]
}
