# Custom checkov checks

Loaded by the `terraform_checkov` pre-commit hook (`--external-checks-dir`). One file per
check, named after its ID (`CKV_BGS_<NNN>`), with the control it enforces in the header.
