# Example: oci/storage

A lab that fits OCI Always Free: the [oci/compute](../compute) example (private VCN, one
`VM.Standard.A1.Flex` instance) plus a 50 GB data volume attached as
`/dev/oracleoci/oraclevdb` (module `oci/block-volume`) and a private bucket with versioning
and object events (module `oci/object-storage`).

Always Free use: 100 of the 200 GB of block storage (boot and data volume), no volume
backups, bucket data counts toward the 20 GB of Object Storage.

```bash
cp terraform.tfvars.example terraform.tfvars   # sandbox compartment, image and public key
terraform init
terraform plan
```

The volume is attached but not formatted or mounted; do that with cloud-init or Ansible
(the device path stays the same across reboots). Credentials are read from `~/.oci/config`.
`terraform.tfvars` is ignored by git.

Validation: L2 and L3 not run yet.
