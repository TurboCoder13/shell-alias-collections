# CI Scripts

Shell scripts for GitHub Actions workflows. Keeping logic in scripts instead
of inline YAML improves readability, testability, and maintainability.

## Scripts

| Script                       | Purpose                             |
| ---------------------------- | ----------------------------------- |
| `validate-json-syntax.sh`    | Validates JSON syntax               |
| `validate-manifest-*.sh`     | Validates manifest.json schema      |
| `validate-collection-*.sh`   | Validates collection file structure |
| `validate-action-pinning.sh` | Checks actions are SHA-pinned       |
| `semantic-pr-title-check.sh` | PR title Conventional Commits check |
| `assign-codeowner.sh`        | Assigns random CODEOWNER to PR      |

## Usage

All scripts support `--help` for usage information:

```bash
./scripts/ci/validate-json-syntax.sh --help
```

## Conventions

- Scripts use `set -euo pipefail` for strict error handling
- Exit codes: 0 = success, 1 = failure
- Environment variables for configuration (documented in each script)
- SPDX license identifier in each file

## Local Testing

Run scripts locally to test before committing:

```bash
# Validate all JSON files
./scripts/ci/validate-json-syntax.sh

# Validate manifest structure
./scripts/ci/validate-manifest-structure.sh

# Validate collection files
./scripts/ci/validate-collection-files.sh

# Check action pinning (non-enforcing)
./scripts/ci/validate-action-pinning.sh

# Check action pinning (enforcing)
ENFORCE=1 ./scripts/ci/validate-action-pinning.sh
```
