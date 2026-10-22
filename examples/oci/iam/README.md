# Example: oci/iam

A workload compartment `acme-app-lab-<region>-cmp` under a sandbox compartment, a dynamic
group for its instances, a policy that lets those instances read buckets and objects in the
compartment, and the Object Storage service policy used by the lifecycle rules of
`oci/object-storage`. IAM is free in OCI; nothing here uses Always Free quota.

The example sets `compartment_enable_delete = true` so `terraform destroy` removes the
compartment. OCI deletes compartments asynchronously and refuses while resources remain in
them. Keep the default (`false`) outside examples.

```bash
cp terraform.tfvars.example terraform.tfvars   # home region, tenancy and parent compartment
terraform init
terraform plan
```

Run it as a user allowed to manage compartments, dynamic groups and policies in the parent
compartment and the tenancy. Credentials are read from `~/.oci/config`. `terraform.tfvars`
is ignored by git.

Validation: L2 and L3 not run yet.
