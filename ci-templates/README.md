# CI templates (disabled)

Pipeline definitions kept as templates only. No CI runs in this repository; the same
checks run locally with `make lint` and `make test`.

To enable one in a consuming repository, copy it to the path the CI system expects
(for example `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`)
and review the pinned versions first.

Templates are added in phase P5 (GitHub Actions, GitLab CI, Jenkins, Azure DevOps).
