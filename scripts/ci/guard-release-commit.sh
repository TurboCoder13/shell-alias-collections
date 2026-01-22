#!/usr/bin/env bash
set -euo pipefail

# guard-release-commit.sh
# Validates that the current commit is a release commit.
#
# Usage:
#   scripts/ci/guard-release-commit.sh

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Validates that the current commit is a release commit.

Usage:
  scripts/ci/guard-release-commit.sh

A release commit must have a message starting with "chore(release):".

Exit codes:
  0 - Valid release commit
  1 - Not a release commit
EOF
	exit 0
fi

COMMIT_MSG=$(git log -1 --format="%s")
echo "Commit message: $COMMIT_MSG"

if [[ "$COMMIT_MSG" =~ ^chore\(release\): ]]; then
	echo "Valid release commit"
	exit 0
else
	echo "Not a release commit (expected 'chore(release): ...')"
	exit 1
fi
