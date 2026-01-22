#!/usr/bin/env bash
set -euo pipefail

# create-release-tag.sh
# Creates and pushes a release tag if version changed.
#
# Usage:
#   scripts/ci/create-release-tag.sh [--version VERSION]
#
# Arguments:
#   --version VERSION  Override version (for manual dispatch)

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Creates and pushes a release tag if version changed.

Usage:
  scripts/ci/create-release-tag.sh [--version VERSION]

Arguments:
  --version VERSION  Override version (for manual dispatch)

Exit codes:
  0 - Success (tag created or no change needed)
  1 - Error occurred
EOF
	exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANUAL_VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	--version)
		MANUAL_VERSION="$2"
		shift 2
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	esac
done

# Determine version and whether to proceed
if [[ -n "$MANUAL_VERSION" ]]; then
	VERSION="$MANUAL_VERSION"
	CHANGED="true"
	echo "Manual version override: $VERSION"
else
	# Check if this is a release commit
	if ! "$SCRIPT_DIR/guard-release-commit.sh" 2>/dev/null; then
		echo "Not a release commit, skipping"
		exit 0
	fi

	# Check version change
	"$SCRIPT_DIR/check-version-change.sh"
	VERSION=$(jq -r '.version' manifest.json)
	PREVIOUS=$(git show HEAD~1:manifest.json 2>/dev/null | jq -r '.version' 2>/dev/null || echo "")

	if [[ "$VERSION" == "$PREVIOUS" ]]; then
		echo "Version unchanged, skipping"
		exit 0
	fi
	CHANGED="true"
fi

TAG_NAME="v$VERSION"

# Check if tag already exists
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
	echo "Tag $TAG_NAME already exists"
	exit 0
fi

# Create and push tag
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
git push origin "$TAG_NAME"

echo "Created and pushed tag $TAG_NAME"

# Output for GitHub Actions
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
	{
		echo "tag=$TAG_NAME"
		echo "version=$VERSION"
		echo "created=true"
	} >>"$GITHUB_OUTPUT"
fi

# GitHub Step Summary
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
	{
		echo "## Release Tag Created"
		echo ""
		echo "- **Tag:** \`$TAG_NAME\`"
		echo "- **Version:** \`$VERSION\`"
	} >>"$GITHUB_STEP_SUMMARY"
fi
