# Security policy

This is a private repository. If you have access and find a vulnerability or a leaked
credential:

1. Do not open an issue or commit a fix that reveals the problem.
2. Report it privately to the owner (GitHub: @BORGESAG).
3. If a secret was committed: rotate it first, then remove it from the history
   (`git filter-repo`), force-push, and verify with `gitleaks git`.

Rules for contributors:

- Values are fictitious: documentation ranges (`10.0.0.0/8`, `192.0.2.0/24`,
  `198.51.100.0/24`, `203.0.113.0/24`), `example.com`, placeholder OCIDs and account IDs.
- No state files, plan files, `*.tfvars` with real data, keys or credentials in git.
- `make lint` must pass before every commit.

Supported version: the latest tag of each module on `main`.
