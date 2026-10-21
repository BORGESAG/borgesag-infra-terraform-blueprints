# Example: oci/network

A lab VCN that fits OCI Always Free: one public subnet behind an internet gateway and one
private subnet, with no NAT or service gateway.

```bash
cp terraform.tfvars.example terraform.tfvars   # set a sandbox compartment OCID
terraform init
terraform plan
```

Credentials are read from `~/.oci/config`. `terraform.tfvars` is ignored by git.

Validation: L2 and L3 not run yet.
