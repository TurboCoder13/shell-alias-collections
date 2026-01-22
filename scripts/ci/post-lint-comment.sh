#!/usr/bin/env bash
set -euo pipefail

# post-lint-comment.sh
# Posts lintro results as a PR comment.
#
# Usage:
#   PR_NUMBER=123 scripts/ci/post-lint-comment.sh
#
# Environment:
#   PR_NUMBER         - The pull request number (required)
#   GH_TOKEN          - GitHub token with pull-requests:write (required)
#   GITHUB_REPOSITORY - Repository in owner/repo format (required)
#   GITHUB_SERVER_URL - GitHub server URL (optional, defaults to https://github.com)
#   GITHUB_RUN_ID     - Workflow run ID for build link (optional)

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Posts lintro results as a PR comment.

Usage:
  PR_NUMBER=123 scripts/ci/post-lint-comment.sh

Environment:
  PR_NUMBER         - The pull request number (required)
  GH_TOKEN          - GitHub token with pull-requests:write (required)
  GITHUB_REPOSITORY - Repository in owner/repo format (required)
  GITHUB_SERVER_URL - GitHub server URL (optional)
  GITHUB_RUN_ID     - Workflow run ID for build link (optional)

This script:
  1. Reads lintro-output.txt
  2. Extracts the execution summary
  3. Formats it as a PR comment matching py-lintro style
  4. Posts or updates the comment on the PR

Exit codes:
  0 - Comment posted successfully
  1 - Error occurred
EOF
	exit 0
fi

if [[ -z "${PR_NUMBER:-}" ]]; then
	echo "Error: PR_NUMBER environment variable is required" >&2
	exit 1
fi

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
	echo "Error: GITHUB_REPOSITORY environment variable is required" >&2
	exit 1
fi

OUTPUT_FILE="lintro-output.txt"
COMMENT_MARKER="<!-- lintro-report -->"
GITHUB_SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"

if [[ ! -f "$OUTPUT_FILE" ]]; then
	echo "No lintro output file found, skipping comment"
	exit 0
fi

# Extract the EXECUTION SUMMARY section
SUMMARY_FILE="lintro-summary.txt"
START_LINE=$(grep -n "EXECUTION SUMMARY" "$OUTPUT_FILE" | head -n1 | cut -d: -f1 || true)
if [[ -n "$START_LINE" ]]; then
	tail -n +"$START_LINE" "$OUTPUT_FILE" >"$SUMMARY_FILE"
else
	# Fallback to last 50 lines
	tail -n 50 "$OUTPUT_FILE" >"$SUMMARY_FILE"
fi

SUMMARY_OUTPUT=$(cat "$SUMMARY_FILE")

# Determine status from exit code
LINTRO_EXIT_CODE="${LINTRO_EXIT_CODE:-0}"
if [[ "$LINTRO_EXIT_CODE" -eq 0 ]]; then
	STATUS="✅ PASSED"
else
	STATUS="⚠️ ISSUES FOUND"
fi

# Build link to workflow run
BUILD_LINK=""
if [[ -n "${GITHUB_RUN_ID:-}" ]]; then
	BUILD_LINK="
---
🔗 **[View full build details](${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID})**"
fi

# Build comment body matching py-lintro format
COMMENT_BODY="$COMMENT_MARKER

## 🔧 Lintro Code Quality Analysis

This PR has been analyzed using **lintro** - our unified code quality tool.

### 📊 Status: $STATUS

**Workflow:**
1. 🔍 Performed code quality checks with \`lintro check\`

### 📋 Results:
\`\`\`
$SUMMARY_OUTPUT
\`\`\`
$BUILD_LINK

*This analysis was performed automatically by the CI pipeline.*"

# Find existing comment with marker
EXISTING_COMMENT_ID=$(gh api "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
	--jq ".[] | select(.body | contains(\"$COMMENT_MARKER\")) | .id" | head -1 || true)

if [[ -n "$EXISTING_COMMENT_ID" ]]; then
	echo "Updating existing comment (ID: $EXISTING_COMMENT_ID)"
	gh api "repos/${GITHUB_REPOSITORY}/issues/comments/${EXISTING_COMMENT_ID}" \
		-X PATCH \
		-f body="$COMMENT_BODY" >/dev/null
else
	echo "Creating new comment"
	gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY"
fi

echo "PR comment posted successfully"
