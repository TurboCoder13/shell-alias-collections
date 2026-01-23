#!/usr/bin/env bash
set -euo pipefail

# update-manifest-version.sh
# Updates the version and lastUpdated fields in manifest.json.
#
# Usage:
#   scripts/ci/update-manifest-version.sh <new-version>

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Updates the version and lastUpdated fields in manifest.json.

Usage:
  scripts/ci/update-manifest-version.sh <new-version>

Arguments:
  new-version  The new semantic version (e.g., 1.2.3)

Exit codes:
  0 - Version updated successfully
  1 - Error occurred
EOF
	exit 0
fi

if [[ $# -lt 1 ]]; then
	echo "Error: new-version argument required" >&2
	echo "Usage: scripts/ci/update-manifest-version.sh <new-version>" >&2
	exit 1
fi

NEW_VERSION="$1"
TODAY=$(date -u +"%Y-%m-%d")

# Validate version format
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Error: Invalid version format. Expected X.Y.Z" >&2
	exit 1
fi

if [[ ! -f "manifest.json" ]]; then
	echo "Error: manifest.json not found" >&2
	exit 1
fi

# Update manifest.json using sed to preserve formatting
# This avoids jq's default multi-line array output that conflicts with prettier
# Patterns allow flexible whitespace around colons and values
sed -i.bak -E \
	-e "s/\"version\"[[:space:]]*:[[:space:]]*\"[0-9]+\.[0-9]+\.[0-9]+\"/\"version\": \"$NEW_VERSION\"/" \
	-e "s/\"lastUpdated\"[[:space:]]*:[[:space:]]*\"[0-9]{4}-[0-9]{2}-[0-9]{2}\"/\"lastUpdated\": \"$TODAY\"/" \
	manifest.json
rm -f manifest.json.bak

# Validate that updates were applied
if ! grep -q "\"version\": \"$NEW_VERSION\"" manifest.json; then
	echo "Error: Failed to update version in manifest.json" >&2
	exit 1
fi
if ! grep -q "\"lastUpdated\": \"$TODAY\"" manifest.json; then
	echo "Error: Failed to update lastUpdated in manifest.json" >&2
	exit 1
fi

echo "Updated manifest.json:"
echo "  version: $NEW_VERSION"
echo "  lastUpdated: $TODAY"
