# GitHub Actions Workflows

This directory contains the CI/CD workflows for shell-alias-collections.

## Workflow Overview

| Workflow                | Trigger        | Purpose                    |
| ----------------------- | -------------- | -------------------------- |
| `validate.yml`          | PR, push       | JSON syntax and schema     |
| `pr-auto-assign.yml`    | PR opened      | Assigns CODEOWNER          |
| `pr-labeler.yml`        | PR opened/sync | Auto-labels by files       |
| `semantic-pr-title.yml` | PR edited      | Conventional Commits check |
| `dependency-review.yml` | PR             | Vulnerable deps check      |
| `validate-action-*.yml` | PR             | SHA-pinned actions check   |
| `scorecards.yml`        | Weekly         | OpenSSF security scorecard |

## Security Features

All workflows use:

- **Strict egress policies** via `step-security/harden-runner`
- **SHA-pinned actions** for supply chain security
- **Minimal permissions** following least privilege
- **Timeout limits** to prevent runaway jobs

See [EGRESS-POLICIES.md](EGRESS-POLICIES.md) for egress policy details.

## PR Workflow

1. Open PR with Conventional Commit title (e.g., `feat: add new collection`)
2. Auto-assigned to a CODEOWNER
3. Auto-labeled based on changed files
4. Validation runs (JSON, schema, action pinning)
5. Dependency review checks for vulnerabilities
6. Merge to main after approval

## Scripts

Workflow logic lives in `scripts/ci/` to keep YAML clean:

- `validate-json-syntax.sh` - JSON syntax validation
- `validate-manifest-structure.sh` - Manifest schema validation
- `validate-collection-files.sh` - Collection file validation
- `validate-action-pinning.sh` - Action SHA pinning check
- `semantic-pr-title-check.sh` - PR title validation
- `assign-codeowner.sh` - Random CODEOWNER assignment
