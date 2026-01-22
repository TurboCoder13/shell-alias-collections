#!/usr/bin/env bash
set -euo pipefail

# check-version-change.sh
# Checks if the version in manifest.json has changed from the previous commit.
#
# Usage:
#   scripts/ci/check-version-change.sh
#
# Output (GitHub Actions):
#   Sets output variables: changed, current_version, previous_version

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Checks if the version in manifest.json has changed from the previous commit.

Usage:
  scripts/ci/check-version-change.sh

Output:
  Sets GitHub Actions output variables:
    changed          - true if version changed, false otherwise
    current_version  - current version from manifest.json
    previous_version - previous version from manifest.json

Exit codes:
  0 - Check completed successfully
  1 - Error occurred
EOF
	exit 0
fi

if ! command -v jq &>/dev/null; then
	echo "Error: jq is required but not installed" >&2
	exit 1
fi

# Get current version
CURRENT_VERSION=$(jq -r '.version' manifest.json)
echo "Current version: $CURRENT_VERSION"

# Get previous version from HEAD~1
PREVIOUS_VERSION=$(git show HEAD~1:manifest.json 2>/dev/null | jq -r '.version' 2>/dev/null || echo "")
echo "Previous version: ${PREVIOUS_VERSION:-"(none)"}"

# Check if tag already exists
TAG_NAME="v${CURRENT_VERSION}"
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
	echo "Tag $TAG_NAME already exists"
	CHANGED="false"
else
	# Determine if version changed
	if [[ "$CURRENT_VERSION" != "$PREVIOUS_VERSION" && -n "$PREVIOUS_VERSION" ]]; then
		CHANGED="true"
		echo "Version changed: $PREVIOUS_VERSION -> $CURRENT_VERSION"
	else
		CHANGED="false"
		echo "Version unchanged"
	fi
fi

# Set GitHub Actions outputs
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
	{
		echo "changed=$CHANGED"
		echo "current_version=$CURRENT_VERSION"
		echo "previous_version=${PREVIOUS_VERSION:-}"
	} >>"$GITHUB_OUTPUT"
fi

echo "changed=$CHANGED"
