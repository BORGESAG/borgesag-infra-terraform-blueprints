# Example: oci/defined-tags

A tag namespace `acme-gov-lab-<region>-tns` in a sandbox compartment with three keys from
ADR 0004: `cost-center` (cost tracking, default `cc-0000`), `environment` (value list,
default `lab`) and `data-classification` (value list). The defaults apply only to new
resources in the sandbox compartment. Tags are free in OCI; nothing here uses Always Free
quota, but the key counts toward the 10 cost-tracking tags of the tenancy.

```bash
cp terraform.tfvars.example terraform.tfvars   # home region, tenancy and sandbox compartment
terraform init
terraform plan
```

Run it as a user allowed to manage tag namespaces and tag defaults in the sandbox
compartment. Credentials are read from `~/.oci/config`. `terraform.tfvars` is ignored by git.

To remove it, set `retired = true` on the module and apply, then run
`terraform destroy -parallelism=1`. OCI deletes one key at a time and each deletion can take
hours (see the module README).

Validation: L2 and L3 not run yet.
