# Sources and Attribution

This document provides detailed attribution for the sources that inspired
and informed the alias collections in this repository.

## Direct Sources

### Oh My Zsh

- **Repository**: <https://github.com/ohmyzsh/ohmyzsh>
- **License**: MIT
- **Usage**: OMZ plugin aliases are fetched dynamically from the official
  repository
- **Plugins referenced**: git, npm, yarn, python, pip, golang, rust, rails,
  bundler, docker, docker-compose, kubectl, terraform, aws, gcloud, heroku,
  brew, macos, systemd, ubuntu, common-aliases, rsync, tmux, screen

### awesome-bash-alias

- **Repository**: <https://github.com/vikaskyadav/awesome-bash-alias>
- **Author**: vikaskyadav
- **Usage**: External source for general bash aliases
- **License**: Check repository for current license

## Inspirational Sources

These blogs and articles inspired the curated collections. The aliases were
written independently but follow similar patterns and use cases.

### nixCraft (cyberciti.biz)

- **URL**: <https://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html>
- **Type**: Blog/Tutorial
- **Inspired collections**:
  - `safety` - Interactive flags for destructive commands
  - `navigation` - Directory shortcuts
  - `git-essentials` - Git workflow shortcuts
  - `file-operations` - File manipulation patterns
  - `system-admin` - Process management
  - `network` - Network diagnostics

### davidjguru

- **URL**: <https://davidjguru.github.io/blog/linux-70-commands-aliases-for-everyday-life>
- **Type**: Blog/Tutorial
- **Inspired collections**:
  - `file-operations` - Search and file management
  - `system-admin` - System monitoring
  - `navigation` - Listing and navigation
  - `network` - Network utilities

## Collection-Specific Attribution

### git-essentials

Original curation inspired by:

- Common git workflow patterns
- Oh My Zsh git plugin conventions
- nixCraft git alias recommendations

### navigation

Original curation inspired by:

- Standard Unix navigation patterns
- nixCraft cd and ls aliases
- davidjguru directory navigation tips

### safety

Original curation inspired by:

- Unix best practices for destructive commands
- nixCraft interactive alias recommendations

### file-operations

Original curation inspired by:

- Standard Unix text processing tools
- davidjguru file management commands
- nixCraft grep and find patterns

### system-admin

Original curation inspired by:

- Common system administration tasks
- davidjguru process management
- nixCraft system monitoring aliases

### network

Original curation inspired by:

- Network troubleshooting patterns
- davidjguru network commands
- nixCraft network diagnostics

## How We Credit Sources

1. **Direct references**: When aliases are fetched from external sources
   (like OMZ plugins), we link directly to the source
2. **Inspirations**: When we write original aliases inspired by blog posts
   or tutorials, we credit them as inspirations
3. **Contributors**: Community members who submit PRs are credited in the
   collection's `attribution.contributors` array

## Licensing Notes

- **Curated collections**: MIT licensed, original work
- **OMZ plugins**: MIT licensed, fetched dynamically
- **External sources**: Check individual repository licenses

## Updating Attribution

When contributing, please:

1. Add any new inspirational sources to this document
2. Update the collection's `attribution` field
3. Include your GitHub username in `contributors` if desired
