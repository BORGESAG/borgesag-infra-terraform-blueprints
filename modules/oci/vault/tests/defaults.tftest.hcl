mock_provider "oci" {}

variables {
  name           = "example-app-dev"
  compartment_id = "ocid1.compartment.oc1..exampleworkload"
  tags           = { environment = "dev" }
}

run "vault_with_hsm_key_and_grants" {
  command = apply

  variables {
    keys = {
      data = {
        service_grantees       = ["objectstorage-sa-saopaulo-1", "blockstorage"]
        dynamic_group_grantees = ["example-app-dev-dg-app"]
      }
    }
  }

  assert {
    condition     = oci_kms_vault.this[0].display_name == "example-app-dev-kv" && oci_kms_vault.this[0].vault_type == "DEFAULT" && oci_kms_vault.this[0].compartment_id == var.compartment_id
    error_message = "The vault must be a DEFAULT vault <name>-kv in the compartment."
  }

  assert {
    condition     = oci_kms_vault.this[0].freeform_tags["managed-by"] == "terraform" && oci_kms_vault.this[0].freeform_tags["iac-module"] == "oci/vault" && oci_kms_vault.this[0].freeform_tags["environment"] == "dev"
    error_message = "Tags must merge the input with managed-by and iac-module."
  }

  assert {
    condition     = oci_kms_key.this["data"].display_name == "example-app-dev-key-data" && oci_kms_key.this["data"].protection_mode == "HSM" && oci_kms_key.this["data"].key_shape[0].algorithm == "AES" && oci_kms_key.this["data"].key_shape[0].length == 32
    error_message = "Keys must default to HSM AES-256 named <name>-key-<key>."
  }

  assert {
    condition     = oci_kms_key.this["data"].management_endpoint == oci_kms_vault.this[0].management_endpoint
    error_message = "Keys must be created in the new vault."
  }

  assert {
    condition     = oci_identity_policy.key_grants["data"].name == "example-app-dev-pol-key-data" && oci_identity_policy.key_grants["data"].compartment_id == var.compartment_id && length(oci_identity_policy.key_grants["data"].statements) == 3
    error_message = "Grantees must get one policy <name>-pol-key-<key> in the compartment."
  }

  assert {
    condition     = oci_identity_policy.key_grants["data"].statements[0] == "Allow service objectstorage-sa-saopaulo-1 to use keys in compartment id ocid1.compartment.oc1..exampleworkload where target.key.id = '${oci_kms_key.this["data"].id}'" && strcontains(oci_identity_policy.key_grants["data"].statements[2], "Allow dynamic-group example-app-dev-dg-app to use key-delegate in compartment id")
    error_message = "Statements must use the compartment OCID and be limited to the key."
  }

  assert {
    condition     = output.key_ids["data"] == oci_kms_key.this["data"].id && output.vault_name == "example-app-dev-kv"
    error_message = "Outputs must expose the vault and key."
  }
}

run "existing_vault_software_and_ecdsa_keys" {
  command = apply

  variables {
    vault_id = "ocid1.vault.oc1..exampleexisting"
    keys = {
      backup = { protection_mode = "SOFTWARE", versions = ["2026q4"] }
      sign   = { algorithm = "ECDSA", length = 48 }
    }
  }

  assert {
    condition     = length(oci_kms_vault.this) == 0 && output.vault_id == "ocid1.vault.oc1..exampleexisting" && output.vault_name == null
    error_message = "An existing vault must be used without creating one."
  }

  assert {
    condition     = oci_kms_key.this["backup"].protection_mode == "SOFTWARE" && length(oci_kms_key_version.this) == 1 && oci_kms_key_version.this["backup.2026q4"].key_id == oci_kms_key.this["backup"].id && oci_kms_key.this["backup"].management_endpoint == data.oci_kms_vault.existing[0].management_endpoint
    error_message = "SOFTWARE keys, versions and the existing vault endpoint must be used."
  }

  assert {
    condition     = oci_kms_key.this["sign"].key_shape[0].algorithm == "ECDSA" && oci_kms_key.this["sign"].key_shape[0].curve_id == "NIST_P384"
    error_message = "ECDSA keys must take the curve from the length."
  }

  assert {
    condition     = length(oci_identity_policy.key_grants) == 0
    error_message = "Keys without grantees must not get a policy."
  }
}

run "rejects_hsm_versions_over_free_limit" {
  command = plan

  variables {
    keys = { for i in range(3) : "k${i}" => { versions = [for v in range(6) : "v${v}"] } }
  }

  expect_failures = [oci_kms_key.this]
}

run "allows_hsm_limit_off" {
  command = plan

  variables {
    hsm_key_version_limit = null
    keys                  = { for i in range(3) : "k${i}" => { versions = [for v in range(6) : "v${v}"] } }
  }
}

run "rejects_bad_key_shape" {
  command = plan

  variables {
    keys = { data = { algorithm = "AES", length = 64 } }
  }

  expect_failures = [var.keys]
}

run "rejects_bad_grantee" {
  command = plan

  variables {
    keys = { data = { group_grantees = ["ops team"] } }
  }

  expect_failures = [var.keys]
}

run "rejects_bad_vault_id" {
  command = plan

  variables {
    vault_id = "ocid1.compartment.oc1..notavault"
  }

  expect_failures = [var.vault_id]
}
