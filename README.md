# Shell Alias Collections

A curated collection of shell aliases for zsh and bash, aggregated from multiple sources with proper attribution.

## Overview

This repository provides a centralized, machine-readable collection of shell aliases that can be consumed by shell configuration tools, editors, and extensions. The collections are:

- **Curated**: Hand-picked aliases with descriptions and attribution
- **Community-contributed**: PRs welcome!
- **Properly attributed**: All inspirations and sources credited

## Usage

### For Tools/Extensions

Fetch the manifest to get all available collections:

```
https://raw.githubusercontent.com/TurboCoder13/shell-alias-collections/main/manifest.json
```

The manifest contains metadata for all collections. Fetch individual collections based on their `source.type`:

- `curated`: Fetch from `source.path` relative to this repo
- `omz-plugin`: Fetch from Oh My Zsh plugin directory
- `external`: Fetch from `source.url`

### For Humans

Browse the `collections/curated/` directory for ready-to-use alias collections:

- **git-essentials.json** - Common git shortcuts
- **navigation.json** - Directory navigation aliases
- **safety.json** - Safer defaults for destructive commands
- **file-operations.json** - File manipulation shortcuts
- **system-admin.json** - System administration aliases
- **network.json** - Network diagnostic utilities

## Collection Format

Each curated collection follows this schema:

```json
{
  "id": "collection-id",
  "name": "Collection Name",
  "description": "What these aliases do",
  "version": "1.0.0",
  "attribution": {
    "inspirations": [
      { "name": "Source Name", "url": "https://..." }
    ],
    "contributors": ["username"]
  },
  "aliases": [
    {
      "name": "alias-name",
      "value": "command to run",
      "description": "What this alias does"
    }
  ]
}
```

## Source Types

| Type | Description | Example |
|------|-------------|---------|
| `curated` | Hand-curated in this repo | git-essentials, navigation |
| `omz-plugin` | Oh My Zsh plugins | git, docker, kubectl |
| `external` | External repositories | awesome-bash-alias |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Adding new curated collections
- Suggesting OMZ plugins to include
- Adding external sources

## Attribution

This project aggregates and curates aliases from various sources. See [SOURCES.md](SOURCES.md) for detailed attribution.

### Primary Inspirations

- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - MIT License
- [nixCraft](https://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html) - Blog inspiration
- [davidjguru](https://davidjguru.github.io/blog/linux-70-commands-aliases-for-everyday-life) - Blog inspiration

## License

MIT License - See [LICENSE](LICENSE)

Curated content is original work inspired by (not copied from) the sources listed. Oh My Zsh plugins are fetched dynamically and subject to their own MIT license.
