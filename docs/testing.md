# Testing

## L1: static checks and mocked tests

Every module and blueprint has a `tests/` folder with `*.tftest.hcl` files that run
without credentials, using `mock_provider` (Terraform 1.7 or later):

```hcl
# modules/<provider>/<module>/tests/defaults.tftest.hcl
mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..exampleuniqueid"
  name           = "example"
}

run "plans_with_defaults" {
  command = plan

  assert {
    condition     = oci_core_vcn.this.display_name == "example-vcn"
    error_message = "The display name must follow <name>-<resource>."
  }
}
```

What to assert at L1:

- the module plans with only the required variables;
- input validation rejects bad values (`expect_failures`);
- names, tags and security defaults (encryption on, no public access) are applied.

Run: `make test` for all, or `make test DIR=modules/oci/network` for one.

## L2: real plan

`terraform plan` against a sandbox account with the example in `examples/<provider>/<pattern>/`.
Record the date, provider version and plan summary (add/change/destroy) in the module README.

## L3: apply and destroy

Only in a sandbox account, with the owner's approval. `apply`, run the checks listed in
the README, `destroy`, and record the evidence (date, versions, logs location) in the README.
