# Tooling

Exact versions used to validate this repository (checked against the official releases
on 2026-10-19). `make versions` compares them with the latest releases.

| Tool | Version | Source |
|---|---|---|
| terraform | 1.16.6 | https://github.com/hashicorp/terraform/releases |
| tflint | 0.64.0 | https://github.com/terraform-linters/tflint/releases |
| trivy | 0.76.0 | https://github.com/aquasecurity/trivy/releases |
| gitleaks | 8.30.1 | https://github.com/gitleaks/gitleaks/releases |
| checkov | 3.3.29 | `requirements.txt` |
| pre-commit | 4.7.0 | `requirements.txt` |
| pre-commit-terraform hooks | 1.109.2 | `.pre-commit-config.yaml` |
| pre-commit-hooks | 6.0.0 | `.pre-commit-config.yaml` |

`requirements.txt` also pins `numpy==2.3.5` (a checkov dependency): NumPy 2.5.4 fails on
CPUs without x86-64-v2 (SSE4.2, POPCNT), which older validation hosts lack.

The validation host runs Linux (bash). On Windows, use WSL or a Linux VM.
