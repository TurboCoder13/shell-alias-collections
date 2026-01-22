#!/usr/bin/env bash
set -euo pipefail

# semantic-pr-title-check.sh
# Validates PR titles follow Conventional Commits format.
#
# Usage:
#   PR_TITLE="feat: add new feature" scripts/ci/semantic-pr-title-check.sh
#   scripts/ci/semantic-pr-title-check.sh --help|-h
#
# Environment:
#   PR_TITLE    - The pull request title to validate (required)
#   TYPES_INPUT - Newline-separated list of allowed types (optional)

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Validates PR titles follow Conventional Commits format.

Usage:
  PR_TITLE="feat: add new feature" scripts/ci/semantic-pr-title-check.sh

Environment:
  PR_TITLE    - The pull request title to validate (required)
  TYPES_INPUT - Newline-separated list of allowed types (optional)
                Default: feat, fix, docs, style, refactor, perf, test, chore, ci, revert

Format:
  <type>(<scope>): <description>
  <type>: <description>

Examples:
  feat: add new collection
  fix(manifest): correct typo in category
  docs: update contributing guide
  chore(ci): update workflow

Exit codes:
  0 - Title is valid
  1 - Title is invalid
EOF
	exit 0
fi

if [[ -z "${PR_TITLE:-}" ]]; then
	echo "Error: PR_TITLE environment variable is required" >&2
	exit 1
fi

# Default allowed types
DEFAULT_TYPES="feat
fix
docs
style
refactor
perf
test
chore
ci
revert"

TYPES="${TYPES_INPUT:-$DEFAULT_TYPES}"
# Handle empty TYPES_INPUT (explicitly set to empty string)
if [[ -z "$TYPES" ]]; then
	TYPES="$DEFAULT_TYPES"
fi

# Sanitize TYPES: remove carriage returns, trim whitespace, filter empty lines
TYPES=$(echo "$TYPES" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$')

# Build regex pattern from types
types_pattern=$(echo "$TYPES" | tr '\n' '|' | sed 's/|$//')

# Conventional commit pattern: type(scope)?: description
# - type: one of the allowed types
# - scope: optional, in parentheses
# - description: starts with lowercase, no period at end
# Pattern: description starts lowercase, no trailing period, min 1 char
pattern="^($types_pattern)(\([a-z0-9_-]+\))?: [a-z](.*[^.])?$"

echo "Validating PR title: $PR_TITLE"
echo ""

if [[ "$PR_TITLE" =~ $pattern ]]; then
	echo "✓ PR title follows Conventional Commits format"
	echo "ok=true" >>"${GITHUB_OUTPUT:-/dev/null}"
	exit 0
else
	echo "✗ PR title does not follow Conventional Commits format" >&2
	echo ""
	echo "Expected format: <type>(<scope>): <description>" >&2
	echo ""
	echo "Allowed types: $(echo "$TYPES" | tr '\n' ', ' | sed 's/, $//')" >&2
	echo ""
	echo "Examples:" >&2
	echo "  feat: add new collection" >&2
	echo "  fix(manifest): correct category order" >&2
	echo "  docs: update readme" >&2
	echo "ok=false" >>"${GITHUB_OUTPUT:-/dev/null}"
	exit 1
fi
