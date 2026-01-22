#!/usr/bin/env bash
set -euo pipefail

# publish-github-release.sh
# Creates a GitHub release with collection artifacts.
#
# Usage:
#   scripts/ci/publish-github-release.sh <tag>
#
# Environment:
#   GH_TOKEN - GitHub token with contents:write

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Creates a GitHub release with collection artifacts.

Usage:
  scripts/ci/publish-github-release.sh <tag>

Arguments:
  tag  The git tag (e.g., v1.2.3)

Environment:
  GH_TOKEN - GitHub token with contents:write

Exit codes:
  0 - Success
  1 - Error occurred
EOF
	exit 0
fi

if [[ $# -lt 1 ]]; then
	echo "Error: tag argument required" >&2
	echo "Usage: scripts/ci/publish-github-release.sh <tag>" >&2
	exit 1
fi

TAG="$1"
VERSION="${TAG#v}"

echo "Publishing release for tag: $TAG (version: $VERSION)"

# Verify tag matches manifest version
MANIFEST_VERSION=$(jq -r '.version' manifest.json)
if [[ "$MANIFEST_VERSION" != "$VERSION" ]]; then
	echo "Error: Tag version ($VERSION) does not match manifest.json ($MANIFEST_VERSION)" >&2
	exit 1
fi
echo "Version verified: $MANIFEST_VERSION"

# Create clean artifacts directory
rm -rf dist
mkdir -p dist

# Create tarball
echo "Creating tarball..."
tar -czf "dist/shell-alias-collections-$VERSION.tar.gz" \
	manifest.json \
	collections/

# Create zip
echo "Creating zip..."
zip -rq "dist/shell-alias-collections-$VERSION.zip" \
	manifest.json \
	collections/

# Generate checksums
echo "Generating checksums..."
(cd dist && sha256sum *.tar.gz *.zip >SHA256SUMS.txt)
cat dist/SHA256SUMS.txt

# Create GitHub release (handle idempotency)
echo "Creating GitHub release..."
if gh release view "$TAG" &>/dev/null; then
	echo "Release $TAG already exists, uploading assets..."
	gh release upload "$TAG" dist/* --clobber
else
	gh release create "$TAG" \
		--title "Release $TAG" \
		--generate-notes \
		dist/*
fi

echo "Published release $TAG"

# GitHub Step Summary
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
	{
		echo "## GitHub Release Published"
		echo ""
		echo "- **Tag:** \`$TAG\`"
		echo "- **Version:** \`$VERSION\`"
		echo ""
		echo "### Artifacts"
		echo "- \`shell-alias-collections-$VERSION.tar.gz\`"
		echo "- \`shell-alias-collections-$VERSION.zip\`"
		echo "- \`SHA256SUMS.txt\`"
	} >>"$GITHUB_STEP_SUMMARY"
fi
