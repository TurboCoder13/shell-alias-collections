#!/usr/bin/env bash
set -euo pipefail

# validate-action-pinning.sh
# Validates that external GitHub Actions are pinned to SHA commits.
#
# Usage:
#   scripts/ci/validate-action-pinning.sh
#   ENFORCE=1 scripts/ci/validate-action-pinning.sh
#   scripts/ci/validate-action-pinning.sh --help|-h
#
# Environment:
#   ENFORCE - If set to 1, exit with error on unpinned actions

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Validates that external GitHub Actions are pinned to SHA commits.

Usage:
  scripts/ci/validate-action-pinning.sh
  ENFORCE=1 scripts/ci/validate-action-pinning.sh

Environment:
  ENFORCE - If set to 1, exit with error on unpinned actions (default: 0)

This script scans all workflow files in .github/workflows/ and checks that
external actions are pinned to full SHA commits (40 hex characters), not
version tags.

Internal actions (same org) are allowed to use version tags.

Exit codes:
  0 - All actions properly pinned (or ENFORCE=0)
  1 - Unpinned actions found and ENFORCE=1
EOF
	exit 0
fi

ENFORCE="${ENFORCE:-0}"
WORKFLOW_DIR=".github/workflows"
unpinned_count=0

if [[ ! -d "$WORKFLOW_DIR" ]]; then
	echo "No workflows directory found, skipping check"
	exit 0
fi

echo "Scanning workflow files for action pinning..."
echo ""

while IFS= read -r -d '' file; do
	# Extract 'uses:' lines, excluding comments
	while IFS= read -r line; do
		# Skip if empty or comment
		[[ -z "$line" ]] && continue
		[[ "$line" =~ ^[[:space:]]*# ]] && continue

		# Extract the action reference
		if [[ "$line" =~ uses:[[:space:]]*[\'\"]?([^\'\"[:space:]]+) ]]; then
			action="${BASH_REMATCH[1]}"

			# Skip local actions (start with ./)
			[[ "$action" == ./* ]] && continue

			# Check if pinned to SHA (40 hex chars after @)
			if [[ "$action" =~ @([a-f0-9]{40})$ ]]; then
				echo "  ✓ $action"
			elif [[ "$action" =~ @(.+)$ ]]; then
				ref="${BASH_REMATCH[1]}"
				echo "  ✗ $action (using tag: $ref)" >&2
				unpinned_count=$((unpinned_count + 1))
			fi
		fi
	done < <(grep -E '^\s*uses:' "$file" 2>/dev/null || true)
done < <(find "$WORKFLOW_DIR" \( -name '*.yml' -o -name '*.yaml' \) -print0 2>/dev/null)

echo ""
if [[ $unpinned_count -eq 0 ]]; then
	echo "All actions are properly pinned to SHA commits!"
	exit 0
elif [[ "$ENFORCE" == "1" ]]; then
	echo "Found $unpinned_count unpinned action(s)" >&2
	echo "All external actions must be pinned to full SHA commits" >&2
	exit 1
else
	echo "Warning: Found $unpinned_count unpinned action(s)"
	echo "Run with ENFORCE=1 to fail on unpinned actions"
	exit 0
fi
