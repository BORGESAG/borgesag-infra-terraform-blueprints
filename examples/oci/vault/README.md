# Example: oci/vault

A vault `acme-app-lab-<region>-kv` (type `DEFAULT`, shared partition) in a sandbox
compartment with one HSM AES-256 key `acme-app-lab-<region>-key-data` and a policy
`acme-app-lab-<region>-pol-key-data` that lets Object Storage and Block Volume use only that
key. It spends 1 of the 20 OCI Always Free HSM key versions.

```bash
cp terraform.tfvars.example terraform.tfvars   # home region and sandbox compartment
terraform init
terraform plan
```

Run it as a user allowed to manage vaults, keys and policies in the sandbox compartment.
Credentials are read from `~/.oci/config`. `terraform.tfvars` is ignored by git.

`terraform destroy` schedules the vault and key for deletion; OCI keeps them pending for 30
days by default (see the module README).

Validation: L2 and L3 not run yet.
