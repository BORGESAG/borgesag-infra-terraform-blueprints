config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Provider rulesets are enabled per provider folder when its first module lands
# (each with an exact version), e.g. tflint-ruleset-aws, tflint-ruleset-azurerm,
# tflint-ruleset-google. OCI and Proxmox have no official ruleset.
