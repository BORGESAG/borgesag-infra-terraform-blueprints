# Policies

```text
checkov/   custom checkov checks (YAML or Python), loaded by the pre-commit hook
opa/       Rego policies for conftest against plan JSON (terraform show -json)
```

Built-in checkov and trivy checks run by default; custom checks cover only what they miss
(naming, mandatory tags, approved regions). Each policy names the control it enforces.
