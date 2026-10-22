# oci/budget

One OCI budget on a compartment, the whole tenancy or a cost-tracking tag, with email alert
rules on actual or forecast spend.

- Upstream: none; resources written on provider `oracle/oci` (ADR 0002 exception, below).
- Validation level: L1, 2026-10-22 on the Linux validation host (pre-commit all hooks
  passed; `terraform test` 8 passed; terraform 1.16.5, trivy 0.75.0, checkov 3.3.29).
  L2 not run, so releases stay at v0.x (ADR 0003).
- Example: [examples/oci/budget](../../../examples/oci/budget).

## Why no upstream module

The OCI Landing Zones governance module `budgets` (v0.1.6, checked 2026-10-22) was reviewed
and not used:

- one alert rule per budget, while OCI allows several (for example 50 %, 100 % and a
  forecast rule on the same budget);
- without an explicit start day it sets `budget_processing_period_start_offset` from
  `timestamp()`, and one-time budgets without dates from `timestamp()` too, so every plan
  shows a change.

`oracle-terraform-modules` has no budget module. Two provider resources are enough.

## Defaults

| Setting | Default | Control |
|---|---|---|
| Target | whole tenancy (root compartment); `target_compartment_id` or `target_tag` | B-12 |
| Period | monthly, starting on day 1 (`start_day`); `single_use` for a one-time budget | |
| Alert rules | actual 50 %, actual 100 %, forecast 100 % of `amount` | B-12 |
| Recipients | required, email; a rule may set its own | |
| Tags | `var.tags` plus `managed-by=terraform`, `iac-module=oci/budget` | ADR 0004 |

Names (ADR 0004, `name` = prefix from `multi/naming`): `<name>-bdg[-<qualifier>]`; alert
rules `<name>-bdg[-<qualifier>]-<key>`.

How OCI budgets behave (Oracle docs "Budgets overview" and "Creating a Budget", checked
2026-10-22):

- Budgets are always created in the root compartment, whatever they target; managing them
  needs `Allow group <group> to manage usage-budgets in tenancy`.
- One budget per compartment and one per tag: creation fails if the target already has a
  budget (for example one made in the console).
- A compartment budget tracks the compartment and its children. A tag budget needs a
  cost-tracking key (see `oci/defined-tags`), written `<namespace>.<key>.<value>`.
- Alerts are evaluated every 24 hours and sent by email; forecast alerts need some days of
  usage first. A budget is a soft limit: it never stops resources.
- `amount` is in the currency of the tenancy rate card; one-time budgets cover at most a year.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | prefix from `multi/naming` (`<org>-<workload>-<env>-<region>`) |
| `qualifier` | string | `null` | suffix after `bdg` |
| `tenancy_id` | string | required | tenancy OCID |
| `description` | string | `Spend budget, managed by Terraform` | |
| `amount` | number | required | whole number, at least 1 |
| `target_compartment_id` | string | `null` | compartment to track; null = tenancy |
| `target_tag` | string | `null` | `<namespace>.<key>.<value>`; excludes `target_compartment_id` |
| `start_day` | number | `1` | first day of a monthly period, 1 to 31 |
| `single_use` | object | `null` | `start_date`, `end_date` (`YYYY-MM-DD`) |
| `recipients` | list(string) | required | email addresses |
| `alert_rules` | map(object) | three rules above | `type` (`ACTUAL`/`FORECAST`), `threshold_type` (`PERCENTAGE`/`ABSOLUTE`), `threshold`, optional `recipients`, `message` |
| `tags` | map(string) | `{}` | freeform tags |
| `defined_tags` | map(string) | `null` | defined tags |

Recipient addresses are personal data: keep them in `terraform.tfvars` (ignored by git) or
a pipeline variable, not in committed code.

## Outputs

`budget_id`, `budget_name`, `alert_rule_ids`.

## Known gaps

- No `INVOICE` processing period and no Notifications topic or Events rule on alerts; add
  them when a blueprint needs automation instead of email.
- OCI does not document a maximum number of alert rules per budget.
- No quota or hard stop: OCI budgets only alert.

## Tests

`tests/defaults.tftest.hcl`, mocked provider: monthly tenancy budget with the default rules;
compartment target, qualifier, start day and one custom absolute rule with its own
recipients; tag target with a one-time period; and rejection of both targets at once, a
fractional amount, a one-time period over a year, a bad rule type and a bad recipient.

```bash
make test DIR=modules/oci/budget
```
