#!/usr/bin/env bash
set -euo pipefail

# validate-manifest-structure.sh
# Validates the structure and required fields of manifest.json.
#
# Usage:
#   scripts/ci/validate-manifest-structure.sh
#   scripts/ci/validate-manifest-structure.sh --help|-h

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Validates manifest.json structure and required fields.

Usage:
  scripts/ci/validate-manifest-structure.sh

Checks:
  - Required top-level fields (version, lastUpdated, collections, categories, sources)
  - Collection entries have required fields (id, name, description, category, source)
  - No duplicate collection IDs
  - Source type-specific required fields
  - All collections reference valid categories

Exit codes:
  0 - Manifest structure valid
  1 - Validation failed
EOF
	exit 0
fi

node -e "
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('manifest.json', 'utf8'));

// Check required fields
if (!manifest.version) throw new Error('Missing version');
if (!manifest.lastUpdated) throw new Error('Missing lastUpdated');
if (!Array.isArray(manifest.collections)) throw new Error('Missing collections array');
if (!Array.isArray(manifest.categories)) throw new Error('Missing categories array');
if (!manifest.sources) throw new Error('Missing sources object');

// Validate each collection
const ids = new Set();
for (const col of manifest.collections) {
  if (!col.id) throw new Error('Collection missing id');
  if (!col.name) throw new Error('Collection ' + col.id + ' missing name');
  if (!col.description) throw new Error('Collection ' + col.id + ' missing description');
  if (!col.category) throw new Error('Collection ' + col.id + ' missing category');
  if (!col.source) throw new Error('Collection ' + col.id + ' missing source');
  if (!col.source.type) throw new Error('Collection ' + col.id + ' missing source.type');

  if (ids.has(col.id)) throw new Error('Duplicate collection id: ' + col.id);
  ids.add(col.id);

  // Validate source type specific fields
  if (col.source.type === 'curated' && !col.source.path) {
    throw new Error('Curated collection ' + col.id + ' missing source.path');
  }
  if (col.source.type === 'omz-plugin' && !col.source.pluginId) {
    throw new Error('OMZ plugin collection ' + col.id + ' missing source.pluginId');
  }
  if (col.source.type === 'external' && !col.source.url) {
    throw new Error('External collection ' + col.id + ' missing source.url');
  }
}

// Validate categories
const categoryIds = new Set();
for (const cat of manifest.categories) {
  if (!cat.id) throw new Error('Category missing id');
  if (typeof cat.order !== 'number') throw new Error('Category ' + cat.id + ' missing order');
  if (categoryIds.has(cat.id)) throw new Error('Duplicate category id: ' + cat.id);
  categoryIds.add(cat.id);
}

// Check all collections reference valid categories
for (const col of manifest.collections) {
  if (!categoryIds.has(col.category)) {
    throw new Error('Collection ' + col.id + ' references unknown category: ' + col.category);
  }
}

console.log('Manifest structure is valid!');
console.log('- ' + manifest.collections.length + ' collections');
console.log('- ' + manifest.categories.length + ' categories');
console.log('- ' + Object.keys(manifest.sources).length + ' sources');
"
