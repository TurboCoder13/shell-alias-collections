#!/usr/bin/env bash
set -euo pipefail

# create-release-pr.sh
# Computes the next version, updates the manifest, and formats code.
# Outputs version info via GITHUB_OUTPUT for the workflow to consume.
# The actual PR creation is handled by peter-evans/create-pull-request.
#
# Usage:
#   scripts/ci/create-release-pr.sh
#
# Environment:
#   MAX_BUMP  - Maximum bump level (major, minor, patch). Default: minor

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Computes the next version, updates the manifest, and formats code.
Outputs version info via GITHUB_OUTPUT for the workflow to consume.

Usage:
  scripts/ci/create-release-pr.sh

Environment:
  MAX_BUMP  - Maximum bump level (major, minor, patch). Default: minor

Outputs (GITHUB_OUTPUT):
  current_version - Current version from manifest.json
  next_version    - Computed next version
  bump_needed     - "true" if version bump is required

Exit codes:
  0 - Success (manifest updated or no change needed)
  1 - Error occurred
EOF
	exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper: write to GITHUB_OUTPUT if available, otherwise print to stdout
output() { if [[ -n "${GITHUB_OUTPUT:-}" ]]; then echo "$1" >>"$GITHUB_OUTPUT"; else echo "output: $1"; fi; }

# Skip if the last commit is already a release commit (prevents loop)
LAST_COMMIT_MSG=$(git log -1 --format="%s")
if [[ "$LAST_COMMIT_MSG" =~ ^chore\(release\): ]]; then
	echo "Last commit is a release commit, skipping to prevent loop"
	output "bump_needed=false"
	exit 0
fi

# Get current version
CURRENT_VERSION=$(jq -r '.version' manifest.json)
echo "Current version: $CURRENT_VERSION"
output "current_version=$CURRENT_VERSION"

# Compute next version
NEXT_VERSION=$("$SCRIPT_DIR/version-bump.sh")
echo "Next version: $NEXT_VERSION"
output "next_version=$NEXT_VERSION"

# Check if version change needed
if [[ "$CURRENT_VERSION" == "$NEXT_VERSION" ]]; then
	echo "No version change needed"
	output "bump_needed=false"
	exit 0
fi

echo "Version bump: $CURRENT_VERSION -> $NEXT_VERSION"
output "bump_needed=true"

# Update manifest version
"$SCRIPT_DIR/update-manifest-version.sh" "$NEXT_VERSION"

# Format code to ensure consistency (uses Docker lintro image)
LINTRO_IMAGE="ghcr.io/turbocoder13/py-lintro:latest"
echo "Running lintro format to ensure code consistency..."
if ! docker run --rm -v "$PWD:/code" -w /code "$LINTRO_IMAGE" lintro format .; then
	echo "Warning: lintro format failed (exit code $?), continuing anyway"
fi

# GitHub Step Summary
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
	{
		echo "## Version Bump Computed"
		echo ""
		echo "- **Current:** \`$CURRENT_VERSION\`"
		echo "- **Next:** \`$NEXT_VERSION\`"
	} >>"$GITHUB_STEP_SUMMARY"
fi
