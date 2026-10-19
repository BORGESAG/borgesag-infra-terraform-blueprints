#!/usr/bin/env bash
# Compare the pinned tool versions (docs/tooling.md) with the latest GitHub releases.
# Needs the GitHub CLI (gh) logged in. Read-only: prints a table, changes nothing.
set -euo pipefail

cd "$(dirname "$0")/.."

declare -A repos=(
  [terraform]=hashicorp/terraform
  [tflint]=terraform-linters/tflint
  [trivy]=aquasecurity/trivy
  [gitleaks]=gitleaks/gitleaks
  [checkov]=bridgecrewio/checkov
  [pre-commit]=pre-commit/pre-commit
  [pre-commit-terraform hooks]=antonbabenko/pre-commit-terraform
  [pre-commit-hooks]=pre-commit/pre-commit-hooks
)

printf '%-28s %-10s %-10s %s\n' TOOL PINNED LATEST STATUS
for tool in "${!repos[@]}"; do
  pinned=$(awk -F'|' -v t="$tool" '{gsub(/^ +| +$/, "", $2)} $2 == t {gsub(/ /, "", $3); print $3}' docs/tooling.md)
  latest=$(gh release view -R "${repos[$tool]}" --json tagName -q .tagName 2>/dev/null || echo "?")
  latest=${latest#v}
  status=current
  [[ "$pinned" == "$latest" ]] || status=outdated
  printf '%-28s %-10s %-10s %s\n' "$tool" "${pinned:-?}" "$latest" "$status"
done | sort
