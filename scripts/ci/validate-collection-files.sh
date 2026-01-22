#!/usr/bin/env bash
set -euo pipefail

# validate-collection-files.sh
# Validates that curated collection files exist and have correct structure.
#
# Usage:
#   scripts/ci/validate-collection-files.sh
#   scripts/ci/validate-collection-files.sh --help|-h

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Validates curated collection files exist and have correct structure.

Usage:
  scripts/ci/validate-collection-files.sh

Checks:
  - All curated collections referenced in manifest exist
  - Each collection has required fields (id, name, description, version, aliases)
  - No duplicate alias names within a collection
  - Each alias has required fields (name, value)

Exit codes:
  0 - All collections valid
  1 - Validation failed
EOF
	exit 0
fi

# Resolve paths from script location for path-independent execution
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export ROOT_DIR

echo "Checking curated collection files exist..."
node -e "
const fs = require('fs');
const path = require('path');
const root = process.env.ROOT_DIR;
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'manifest.json'), 'utf8'));

for (const col of manifest.collections) {
  if (col.source.type === 'curated') {
    const filePath = path.join(root, col.source.path);
    if (!fs.existsSync(filePath)) {
      throw new Error('Curated collection file not found: ' + col.source.path);
    }
    console.log('  ✓ ' + col.source.path);
  }
}
console.log('All curated collection files exist!');
"

echo ""
echo "Validating curated collection structure..."
node -e "
const fs = require('fs');
const path = require('path');
const root = process.env.ROOT_DIR;

const curatedDir = path.join(root, 'collections/curated');
const files = fs.readdirSync(curatedDir).filter(f => f.endsWith('.json'));

for (const file of files) {
  const filePath = path.join(curatedDir, file);
  const col = JSON.parse(fs.readFileSync(filePath, 'utf8'));

  if (!col.id) throw new Error(file + ' missing id');
  if (!col.name) throw new Error(file + ' missing name');
  if (!col.description) throw new Error(file + ' missing description');
  if (!col.version) throw new Error(file + ' missing version');
  if (!Array.isArray(col.aliases)) throw new Error(file + ' missing aliases array');

  // Validate aliases
  const aliasNames = new Set();
  for (const alias of col.aliases) {
    if (!alias.name) throw new Error(file + ' has alias missing name');
    if (!alias.value) throw new Error(file + ' has alias ' + alias.name + ' missing value');
    if (aliasNames.has(alias.name)) {
      throw new Error(file + ' has duplicate alias: ' + alias.name);
    }
    aliasNames.add(alias.name);
  }

  console.log('  ✓ ' + file + ': ' + col.aliases.length + ' aliases');
}
console.log('All curated collections are valid!');
"
