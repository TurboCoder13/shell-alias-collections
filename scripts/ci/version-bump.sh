#!/usr/bin/env bash
set -euo pipefail

# version-bump.sh
# Computes the next semantic version based on conventional commits.
#
# Usage:
#   scripts/ci/version-bump.sh [--current-version VERSION]
#
# Environment:
#   MAX_BUMP - Maximum bump level allowed (major, minor, patch). Default: minor
#
# Output:
#   Prints the next version to stdout

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Computes the next semantic version based on conventional commits.

Usage:
  scripts/ci/version-bump.sh [--current-version VERSION]

Options:
  --current-version VERSION  Override current version (default: read from manifest.json)

Environment:
  MAX_BUMP  Maximum bump level allowed (major, minor, patch). Default: minor

Exit codes:
  0 - Version computed successfully
  1 - Error occurred
EOF
	exit 0
fi

# Parse arguments
CURRENT_VERSION=""
while [[ $# -gt 0 ]]; do
	case "$1" in
	--current-version)
		CURRENT_VERSION="$2"
		shift 2
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	esac
done

# Get current version from manifest.json if not provided
if [[ -z "$CURRENT_VERSION" ]]; then
	if ! command -v jq &>/dev/null; then
		echo "Error: jq is required but not installed" >&2
		exit 1
	fi
	CURRENT_VERSION=$(jq -r '.version' manifest.json)
fi

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<<"$CURRENT_VERSION"

# Get the last tag or use initial commit
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [[ -z "$LAST_TAG" ]]; then
	# No tags, get all commits
	COMMIT_RANGE="HEAD"
else
	COMMIT_RANGE="${LAST_TAG}..HEAD"
fi

# Analyze commits for bump type
BUMP_TYPE="none"
HAS_BREAKING=false
HAS_FEAT=false
HAS_FIX=false

# Regex patterns for commit analysis (variables avoid shellcheck parsing issues)
BREAKING_BANG_REGEX='^[a-z]+(\([^)]+\))?!:'
BREAKING_CHANGE_REGEX='BREAKING[[:space:]]CHANGE'
FEAT_REGEX='^feat(\([^)]+\))?:'
PATCH_REGEX='^(fix|perf|refactor|docs|style|test|chore|ci)(\([^)]+\))?:'

while IFS= read -r commit_msg; do
	[[ -z "$commit_msg" ]] && continue

	# Check for breaking changes
	if [[ "$commit_msg" =~ $BREAKING_BANG_REGEX ]] || [[ "$commit_msg" =~ $BREAKING_CHANGE_REGEX ]]; then
		HAS_BREAKING=true
	fi

	# Check for features
	if [[ "$commit_msg" =~ $FEAT_REGEX ]]; then
		HAS_FEAT=true
	fi

	# Check for fixes and other patch-level changes
	if [[ "$commit_msg" =~ $PATCH_REGEX ]]; then
		HAS_FIX=true
	fi
done < <(git log --format="%s" "$COMMIT_RANGE" 2>/dev/null || true)

# Determine bump type based on commits
if [[ "$HAS_BREAKING" == true ]]; then
	BUMP_TYPE="major"
elif [[ "$HAS_FEAT" == true ]]; then
	BUMP_TYPE="minor"
elif [[ "$HAS_FIX" == true ]]; then
	BUMP_TYPE="patch"
fi

# Apply MAX_BUMP constraint
MAX_BUMP="${MAX_BUMP:-minor}"
case "$MAX_BUMP" in
patch)
	if [[ "$BUMP_TYPE" == "major" || "$BUMP_TYPE" == "minor" ]]; then
		BUMP_TYPE="patch"
	fi
	;;
minor)
	if [[ "$BUMP_TYPE" == "major" ]]; then
		BUMP_TYPE="minor"
	fi
	;;
major)
	# No constraint
	;;
esac

# Calculate next version
case "$BUMP_TYPE" in
major)
	MAJOR=$((MAJOR + 1))
	MINOR=0
	PATCH=0
	;;
minor)
	MINOR=$((MINOR + 1))
	PATCH=0
	;;
patch)
	PATCH=$((PATCH + 1))
	;;
none)
	# No version change needed
	echo "$CURRENT_VERSION"
	exit 0
	;;
esac

NEXT_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "$NEXT_VERSION"
