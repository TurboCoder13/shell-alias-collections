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

errors=0

echo "Validating manifest.json..."
if python3 -m json.tool manifest.json >/dev/null 2>&1; then
	echo "  ✓ manifest.json is valid JSON"
else
	echo "  ✗ manifest.json is invalid JSON" >&2
	errors=$((errors + 1))
fi

echo ""
echo "Validating curated collections..."
if compgen -G "collections/curated/*.json" >/dev/null 2>&1; then
	for file in collections/curated/*.json; do
		if python3 -m json.tool "$file" >/dev/null 2>&1; then
			echo "  ✓ $file"
		else
			echo "  ✗ $file is invalid JSON" >&2
			errors=$((errors + 1))
		fi
	done
else
	echo "  (no curated collections found)"
fi

echo ""
echo "Validating community collections..."
if compgen -G "collections/community/*.json" >/dev/null 2>&1; then
	for file in collections/community/*.json; do
		if [[ -f "$file" ]]; then
			if python3 -m json.tool "$file" >/dev/null 2>&1; then
				echo "  ✓ $file"
			else
				echo "  ✗ $file is invalid JSON" >&2
				errors=$((errors + 1))
			fi
		fi
	done
else
	echo "  (no community collections found)"
fi

echo ""
if [[ $errors -eq 0 ]]; then
	echo "All JSON files are valid!"
	exit 0
else
	echo "Found $errors invalid JSON file(s)" >&2
	exit 1
fi
