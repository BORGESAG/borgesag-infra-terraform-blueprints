# Standard entry points. Usage: make <target> [DIR=<module or blueprint path>]
SHELL := /bin/bash
.DEFAULT_GOAL := help

VENV := .venv/bin
DIR ?=
TEST_DIRS = $(if $(DIR),$(DIR),$(shell find modules blueprints -type d -name tests -prune -exec dirname {} \; 2>/dev/null | sort))

.PHONY: help setup lint test versions

help: ## Show the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

setup: ## Create .venv with pinned tooling (requirements.txt) and install the git hook
	python3 -m venv .venv
	$(VENV)/pip install --quiet -r requirements.txt
	$(VENV)/pre-commit install

lint: ## All pre-commit checks on every file (gitleaks, fmt, validate, tflint, checkov, trivy)
	$(VENV)/pre-commit run --all-files

test: ## terraform test (L1, mock_provider) in every module/blueprint with tests/, or DIR=<path>
	@test -n "$(strip $(TEST_DIRS))" || { echo "No tests/ folders yet"; exit 0; }
	@for d in $(TEST_DIRS); do echo "== $$d"; terraform -chdir=$$d init -backend=false -input=false >/dev/null && terraform -chdir=$$d test || exit 1; done

versions: ## Pinned versus latest release of terraform, tflint, checkov, trivy, gitleaks, pre-commit hooks
	scripts/versions.sh
