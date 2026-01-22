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

if ! command -v jq &>/dev/null; then
	echo "Error: jq is required but not installed" >&2
	exit 1
fi

# Update manifest.json
TEMP_FILE=$(mktemp)
jq --arg version "$NEW_VERSION" --arg date "$TODAY" \
	'.version = $version | .lastUpdated = $date' \
	manifest.json >"$TEMP_FILE"

mv "$TEMP_FILE" manifest.json

echo "Updated manifest.json:"
echo "  version: $NEW_VERSION"
echo "  lastUpdated: $TODAY"
