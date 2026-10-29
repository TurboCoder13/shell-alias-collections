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

## All-checks gate

`all-checks-gate.yml` runs on main pushes, PR lifecycle/title changes and
merge-queue requests. Its dedicated `gate / ✅ All Checks Passed` check waits
for other workflows, check runs and commit statuses on the same head. It fails
closed on drafts, empty check sets, API failures and failed/cancelled checks;
upstream accepts successful, skipped and neutral conclusions.

The caller pins lgtm-ci v0.79.2 and inherits its block-mode egress policy. This
version includes the harden-runner DNS fix; no audit override or ignored checks
are added. A merge queue still needs other validation workflows to support
`merge_group`; the gate will not manufacture validation for an empty queue head.

The caller alone does **not** enforce merge protection. Add its exact context to
a separate required-check ruleset only after merging it and verifying genuine
main-branch execution, preserving every existing protection.

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
