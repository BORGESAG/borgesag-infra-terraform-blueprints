# Example: oci/compute

A lab instance that fits OCI Always Free: a VCN with one private subnet (module
`oci/network`) and one `VM.Standard.A1.Flex` instance with 1 OCPU, 6 GB, a 50 GB boot
volume, no public IP and no backup policy.

The instance has no route to the internet (no gateway). Reach it through the OCI Bastion
service or add `create_nat_gateway` to the network (not Always Free).

```bash
cp terraform.tfvars.example terraform.tfvars   # sandbox compartment, image and public key
oci compute image list --compartment-id <compartment> --shape VM.Standard.A1.Flex \
  --operating-system "Oracle Linux" --sort-by TIMECREATED --query 'data[0].id'
terraform init
terraform plan
```

Credentials are read from `~/.oci/config`. `terraform.tfvars` is ignored by git.

Validation: L2 and L3 not run yet.
