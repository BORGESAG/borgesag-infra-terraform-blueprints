# Example: oci/budget

A free-tier guard: a monthly budget `acme-finops-lab-<region>-bdg` of 1 (rate card currency)
on the whole tenancy, with one alert on any actual spend (absolute 0.01) and one when the
month is forecast to pass the budget. OCI evaluates alerts every 24 hours and only sends
email; nothing is stopped.

OCI allows one budget per compartment: if the tenancy root already has a budget (for
example one made in the console), set `target_compartment_id` to a sandbox compartment or
import the existing budget.

```bash
cp terraform.tfvars.example terraform.tfvars   # region, tenancy and alert emails
terraform init
terraform plan
```

Run it as a user allowed to `manage usage-budgets in tenancy`. Credentials are read from
`~/.oci/config`. `terraform.tfvars` holds the email addresses and is ignored by git.

Validation: L2 and L3 not run yet.
