# Contributing to Shell Alias Collections

Thank you for your interest in contributing! This document explains how to
add new collections, improve existing ones, or suggest external sources.

## Types of Contributions

### 1. Adding Curated Collections

Create a new JSON file in `collections/curated/` following this schema:

```json
{
  "id": "your-collection-id",
  "name": "Your Collection Name",
  "description": "Brief description of what these aliases do",
  "version": "1.0.0",
  "attribution": {
    "inspirations": [
      {
        "name": "Source Name",
        "url": "https://source-url.com"
      }
    ],
    "contributors": ["your-github-username"]
  },
  "aliases": [
    {
      "name": "alias-name",
      "value": "command value",
      "description": "What this alias does"
    }
  ]
}
```

Then add an entry to `manifest.json`:

```json
{
  "id": "your-collection-id",
  "name": "Your Collection Name",
  "description": "Brief description",
  "category": "Development|DevOps|System|Utilities|Community",
  "tags": ["relevant", "tags"],
  "source": {
    "type": "curated",
    "path": "collections/curated/your-collection-id.json"
  }
}
```

### 2. Suggesting OMZ Plugins

If you'd like an Oh My Zsh plugin included in the manifest:

1. Verify the plugin exists at `https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/PLUGIN_NAME`
2. Verify it contains alias definitions
3. Open an issue or PR adding the entry to `manifest.json`:

```json
{
  "id": "plugin-id",
  "name": "Plugin Name",
  "description": "What these aliases do",
  "category": "Appropriate Category",
  "tags": ["relevant", "tags"],
  "source": {
    "type": "omz-plugin",
    "pluginId": "plugin-id"
  }
}
```

### 3. Adding External Sources

For external GitHub repositories or other sources:

1. Verify the license allows redistribution/reference
2. Test that the URL is accessible
3. Add to `manifest.json`:

```json
{
  "id": "external-source-id",
  "name": "Source Name",
  "description": "Description",
  "category": "Category",
  "tags": ["tags"],
  "source": {
    "type": "external",
    "url": "https://raw.githubusercontent.com/user/repo/branch/file.sh",
    "parser": "bash"
  }
}
```

Also add attribution to `SOURCES.md` for new external sources.

### 4. Improving Existing Collections

- Fix typos or improve descriptions
- Add missing aliases to curated collections
- Update outdated command syntax

## Guidelines

### Alias Quality

- **Useful**: Aliases should save meaningful time or keystrokes
- **Memorable**: Short names should be intuitive
- **Safe**: Don't include aliases that could cause accidental data loss
- **Documented**: Every alias needs a description

### Attribution

- Always credit your sources
- If inspired by a blog or tutorial, add it to `inspirations`
- Don't copy aliases verbatim without permission
- Write original aliases inspired by patterns you've seen

### Naming Conventions

- Collection IDs: lowercase with hyphens (`git-essentials`)
- Alias names: short, lowercase, commonly used abbreviations
- Categories: One of `Development`, `DevOps`, `System`, `Utilities`, `Community`

### Testing

Before submitting:

1. Validate JSON syntax
2. Test aliases work in zsh/bash
3. Ensure no duplicate IDs in manifest

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b add-new-collection`)
3. Make your changes
4. Validate JSON files
5. Update `SOURCES.md` if adding new sources
6. Submit PR with clear description

## Code of Conduct

- Be respectful and constructive
- Give credit where credit is due
- Help maintain quality over quantity

## Questions?

Open an issue if you have questions about contributing!
