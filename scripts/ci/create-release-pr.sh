#!/usr/bin/env bash
set -euo pipefail

# create-release-pr.sh
# Creates a release PR with version bump if needed.
#
# Usage:
#   scripts/ci/create-release-pr.sh
#
# Environment:
#   GH_TOKEN  - GitHub token with contents:write and pull-requests:write
#   MAX_BUMP  - Maximum bump level (major, minor, patch). Default: minor

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Creates a release PR with version bump if needed.

Usage:
  scripts/ci/create-release-pr.sh

Environment:
  GH_TOKEN  - GitHub token with contents:write and pull-requests:write
  MAX_BUMP  - Maximum bump level (major, minor, patch). Default: minor

Exit codes:
  0 - Success (PR created or no change needed)
  1 - Error occurred
EOF
	exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get current version
CURRENT_VERSION=$(jq -r '.version' manifest.json)
echo "Current version: $CURRENT_VERSION"

# Compute next version
NEXT_VERSION=$("$SCRIPT_DIR/version-bump.sh")
echo "Next version: $NEXT_VERSION"

# Check if version change needed
if [[ "$CURRENT_VERSION" == "$NEXT_VERSION" ]]; then
	echo "No version change needed"
	exit 0
fi

echo "Version bump: $CURRENT_VERSION -> $NEXT_VERSION"

# Check for existing release PR
EXISTING=$(gh pr list --head "release/v$NEXT_VERSION" --json number --jq '.[0].number // empty' || true)
if [[ -n "$EXISTING" ]]; then
	echo "Release PR #$EXISTING already exists"
	exit 0
fi

# Create release branch
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git checkout -b "release/v$NEXT_VERSION"

# Update manifest version
"$SCRIPT_DIR/update-manifest-version.sh" "$NEXT_VERSION"

# Commit and push
git add manifest.json
git commit -m "chore(release): prepare v$NEXT_VERSION"
git push -u origin "release/v$NEXT_VERSION"

# Create PR
gh pr create \
	--title "chore(release): prepare v$NEXT_VERSION" \
	--body "$(
		cat <<EOF
## Release v$NEXT_VERSION

Automated version bump from \`$CURRENT_VERSION\` to \`$NEXT_VERSION\`.

### Changes
- Updates \`manifest.json\` version and lastUpdated fields

### What happens next
1. This PR will be reviewed and merged
2. A git tag \`v$NEXT_VERSION\` will be created automatically
3. A GitHub Release will be published with the collections artifact

---
*This PR was created automatically by the release workflow.*
EOF
	)" \
	--label "release-bump" \
	--base main

echo "Created release PR for v$NEXT_VERSION"
