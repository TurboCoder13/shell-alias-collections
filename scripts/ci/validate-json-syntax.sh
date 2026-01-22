#!/usr/bin/env bash
set -euo pipefail

# validate-json-syntax.sh
# Validates JSON syntax for all collection files.
#
# Usage:
#   scripts/ci/validate-json-syntax.sh
#   scripts/ci/validate-json-syntax.sh --help|-h

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Validates JSON syntax for manifest and collection files.

Usage:
  scripts/ci/validate-json-syntax.sh

This script checks:
  - manifest.json
  - collections/curated/*.json
  - collections/community/*.json (if present)

Exit codes:
  0 - All files valid
  1 - One or more files invalid
EOF
	exit 0
fi

# Verify python3 is available
if ! command -v python3 &>/dev/null; then
	echo "Error: python3 is required but not found" >&2
	exit 1
fi

errors=0

# Helper function to validate JSON files matching a glob pattern
validate_glob() {
	local label="$1"
	local pattern="$2"

	echo ""
	echo "Validating ${label} collections..."
	if compgen -G "$pattern" >/dev/null 2>&1; then
		for file in $pattern; do
			if [[ -f "$file" ]]; then
				error_output=$(python3 -m json.tool "$file" 2>&1 >/dev/null) || true
				if [[ -z "$error_output" ]]; then
					echo "  ✓ $file"
				else
					echo "  ✗ $file is invalid JSON: $error_output" >&2
					errors=$((errors + 1))
				fi
			fi
		done
	else
		echo "  (no ${label} collections found)"
	fi
}

echo "Validating manifest.json..."
if [[ ! -r "manifest.json" ]]; then
	echo "  ✗ manifest.json is missing or unreadable" >&2
	errors=$((errors + 1))
else
	error_output=$(python3 -m json.tool manifest.json 2>&1 >/dev/null) || true
	if [[ -z "$error_output" ]]; then
		echo "  ✓ manifest.json is valid JSON"
	else
		echo "  ✗ manifest.json is invalid JSON: $error_output" >&2
		errors=$((errors + 1))
	fi
fi

validate_glob "curated" "collections/curated/*.json"
validate_glob "community" "collections/community/*.json"

echo ""
if [[ $errors -eq 0 ]]; then
	echo "All JSON files are valid!"
	exit 0
else
	echo "Found $errors invalid JSON file(s)" >&2
	exit 1
fi
