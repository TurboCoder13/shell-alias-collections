#!/usr/bin/env bash
set -euo pipefail

# run-lintro.sh
# Runs lintro check and captures output for CI.
#
# Usage:
#   scripts/ci/run-lintro.sh

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Runs lintro check and captures output for CI.

Usage:
  scripts/ci/run-lintro.sh

Output:
  Creates lintro-output.txt with the check results.
  Exit code reflects whether linting passed or failed.

Exit codes:
  0 - All checks passed
  1 - Linting issues found
EOF
	exit 0
fi

OUTPUT_FILE="lintro-output.txt"

echo "Running lintro check..."

# Run lintro and capture output, preserving exit code
set +e
uv tool run lintro check . --output-format grid 2>&1 | tee "$OUTPUT_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

# Export for other steps
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
	echo "exit_code=$EXIT_CODE" >>"$GITHUB_OUTPUT"
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
	echo "LINTRO_EXIT_CODE=$EXIT_CODE" >>"$GITHUB_ENV"
fi

if [[ $EXIT_CODE -eq 0 ]]; then
	echo "Linting passed!"
else
	echo "Linting found issues (exit code: $EXIT_CODE)"
fi

exit "$EXIT_CODE"
