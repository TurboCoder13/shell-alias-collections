#!/usr/bin/env bash
set -euo pipefail

# assign-codeowner.sh
# Assigns a random CODEOWNER to a pull request.
#
# Usage:
#   PR_NUMBER=123 GH_TOKEN=xxx scripts/ci/assign-codeowner.sh
#   scripts/ci/assign-codeowner.sh --help|-h
#
# Environment:
#   PR_NUMBER - The pull request number (required)
#   GH_TOKEN  - GitHub token with pull-requests:write permission (required)

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Assigns a random CODEOWNER to a pull request.

Usage:
  PR_NUMBER=123 GH_TOKEN=xxx scripts/ci/assign-codeowner.sh

Environment:
  PR_NUMBER - The pull request number (required)
  GH_TOKEN  - GitHub token with pull-requests:write permission (required)

This script:
  1. Reads .github/CODEOWNERS
  2. Extracts individual usernames (excludes team entries)
  3. Randomly selects one
  4. Assigns them to the PR

Exit codes:
  0 - Assignment successful or no CODEOWNERS found
  1 - Required environment variables missing
EOF
	exit 0
fi

if [[ -z "${PR_NUMBER:-}" ]]; then
	echo "Error: PR_NUMBER environment variable is required" >&2
	exit 1
fi

if [[ -z "${GH_TOKEN:-}" ]]; then
	echo "Error: GH_TOKEN environment variable is required" >&2
	exit 1
fi

if [[ ! -f ".github/CODEOWNERS" ]]; then
	echo "No CODEOWNERS file found, skipping assignment"
	exit 0
fi

# Extract usernames from CODEOWNERS using token-based parsing
# Only accepts tokens that are exactly @username (no dots, slashes, or emails)
owners=$(awk '{
	for (i = 1; i <= NF; i++) {
		if ($i ~ /^@[A-Za-z0-9_-]+$/) {
			print substr($i, 2)
		}
	}
}' .github/CODEOWNERS | sort -u | grep -E '^[A-Za-z0-9_-]+$' || true)

if [[ -z "$owners" ]]; then
	echo "No valid individual CODEOWNERS found, skipping assignment"
	exit 0
fi

# Convert to array using mapfile (shellcheck-safe)
mapfile -t owner_array <<<"$owners"
count=${#owner_array[@]}

if [[ $count -eq 0 ]]; then
	echo "No valid individual CODEOWNERS found, skipping assignment"
	exit 0
fi

random_index=$((RANDOM % count))
selected="${owner_array[$random_index]}"

echo "Selected assignee: $selected (from $count CODEOWNERS)"
gh pr edit "$PR_NUMBER" --add-assignee "$selected"
