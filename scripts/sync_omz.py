#!/usr/bin/env python3
"""
Sync Oh My Zsh plugin aliases to curated JSON files.

This script fetches aliases from Oh My Zsh plugins and external sources,
parses them, and saves them as curated JSON files. This ensures versioned,
stable alias collections that don't change unexpectedly.

Usage:
    python scripts/sync_omz.py [--dry-run] [--plugin PLUGIN]
"""

from __future__ import annotations

import argparse
import json
import re
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from collections.abc import Sequence

# Repository paths
REPO_ROOT = Path(__file__).parent.parent
COLLECTIONS_DIR = REPO_ROOT / "collections" / "omz"
MANIFEST_PATH = REPO_ROOT / "manifest.json"

# Oh My Zsh base URL
OMZ_BASE_URL = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins"

# Regex patterns for parsing aliases
ALIAS_PATTERN = re.compile(
    r"""
    ^\s*alias\s+               # 'alias' keyword
    (?P<flags>-[gs]\s+)?       # Optional flags like -g or -s
    (?P<name>[a-zA-Z0-9_-]+)   # Alias name
    \s*=\s*                    # Equals sign
    (?P<quote>['"])            # Opening quote
    (?P<value>.+?)             # Alias value (non-greedy)
    (?P=quote)                 # Matching closing quote
    \s*$                       # End of line
    """,
    re.VERBOSE | re.MULTILINE,
)

# Pattern to extract description from comment above alias
COMMENT_PATTERN = re.compile(r"^\s*#\s*(.+)$")


@dataclass
class ParsedAlias:
    """A parsed alias with optional description."""

    name: str
    value: str
    description: str | None = None
    is_global: bool = False


@dataclass
class PluginConfig:
    """Configuration for an OMZ plugin."""

    plugin_id: str
    name: str
    description: str
    category: str
    tags: list[str]


# Plugin configurations matching manifest.json
PLUGINS: list[PluginConfig] = [
    PluginConfig(
        "git",
        "Git (OMZ)",
        "Git aliases from Oh My Zsh",
        "Development",
        ["git", "version-control"],
    ),
    PluginConfig(
        "npm",
        "NPM",
        "NPM package manager aliases",
        "Development",
        ["npm", "node", "javascript"],
    ),
    PluginConfig(
        "yarn",
        "Yarn",
        "Yarn package manager aliases",
        "Development",
        ["yarn", "node", "javascript"],
    ),
    PluginConfig(
        "python",
        "Python",
        "Python development aliases",
        "Development",
        ["python", "py"],
    ),
    PluginConfig(
        "pip",
        "Pip",
        "Python pip package manager aliases",
        "Development",
        ["pip", "python", "packages"],
    ),
    PluginConfig(
        "golang",
        "Go",
        "Go language development aliases",
        "Development",
        ["go", "golang"],
    ),
    PluginConfig(
        "rust",
        "Rust",
        "Rust language development aliases",
        "Development",
        ["rust", "cargo"],
    ),
    PluginConfig(
        "rails",
        "Rails",
        "Ruby on Rails development aliases",
        "Development",
        ["rails", "ruby"],
    ),
    PluginConfig(
        "bundler",
        "Bundler",
        "Ruby Bundler aliases",
        "Development",
        ["bundler", "ruby", "gems"],
    ),
    PluginConfig(
        "docker",
        "Docker",
        "Docker container aliases",
        "DevOps",
        ["docker", "containers"],
    ),
    PluginConfig(
        "docker-compose",
        "Docker Compose",
        "Docker Compose orchestration aliases",
        "DevOps",
        ["docker", "compose", "containers"],
    ),
    PluginConfig(
        "kubectl",
        "Kubernetes",
        "Kubernetes kubectl aliases",
        "DevOps",
        ["kubernetes", "k8s", "kubectl"],
    ),
    PluginConfig(
        "terraform",
        "Terraform",
        "Terraform infrastructure as code aliases",
        "DevOps",
        ["terraform", "infrastructure"],
    ),
    PluginConfig(
        "aws",
        "AWS CLI",
        "Amazon Web Services CLI aliases",
        "DevOps",
        ["aws", "cloud"],
    ),
    PluginConfig(
        "gcloud",
        "Google Cloud",
        "Google Cloud Platform aliases",
        "DevOps",
        ["gcloud", "gcp", "cloud"],
    ),
    PluginConfig(
        "heroku",
        "Heroku",
        "Heroku platform aliases",
        "DevOps",
        ["heroku", "paas"],
    ),
    PluginConfig(
        "brew",
        "Homebrew",
        "Homebrew package manager aliases",
        "System",
        ["brew", "homebrew", "macos"],
    ),
    PluginConfig(
        "macos",
        "macOS",
        "macOS-specific aliases",
        "System",
        ["macos", "osx", "apple"],
    ),
    PluginConfig(
        "systemd",
        "Systemd",
        "Linux systemd service management aliases",
        "System",
        ["systemd", "linux", "services"],
    ),
    PluginConfig(
        "ubuntu",
        "Ubuntu",
        "Ubuntu Linux aliases",
        "System",
        ["ubuntu", "linux", "apt"],
    ),
    PluginConfig(
        "common-aliases",
        "Common Shell",
        "Common shell aliases for everyday use",
        "Utilities",
        ["common", "shell", "general"],
    ),
    PluginConfig(
        "rsync",
        "Rsync",
        "Rsync file synchronization aliases",
        "Utilities",
        ["rsync", "sync", "backup"],
    ),
    PluginConfig(
        "tmux",
        "Tmux",
        "Tmux terminal multiplexer aliases",
        "Utilities",
        ["tmux", "terminal"],
    ),
    PluginConfig(
        "screen",
        "Screen",
        "GNU Screen terminal multiplexer aliases",
        "Utilities",
        ["screen", "terminal"],
    ),
]


def fetch_url(url: str) -> str:
    """Fetch content from a URL."""
    print(f"  Fetching: {url}")
    # URLs are hardcoded to trusted OMZ GitHub sources, not user-controlled
    # nosec B310
    # nosemgrep: python.lang.security.audit.dynamic-urllib-use-detected.dynamic-urllib-use-detected
    with urllib.request.urlopen(url, timeout=30) as response:  # noqa: S310 - same as above
        content: bytes = response.read()
        return content.decode("utf-8")


def parse_aliases(content: str) -> list[ParsedAlias]:
    """Parse aliases from shell script content."""
    aliases: list[ParsedAlias] = []
    lines = content.split("\n")

    pending_comment: str | None = None

    for line in lines:
        # Check for comment that might describe the next alias
        comment_match = COMMENT_PATTERN.match(line)
        if comment_match:
            comment_text = comment_match.group(1).strip()
            # Skip shebang, section headers, and other non-description comments
            if not comment_text.startswith("!") and not comment_text.startswith("-"):
                pending_comment = comment_text
            continue

        # Check for alias definition
        alias_match = ALIAS_PATTERN.match(line)
        if alias_match:
            name = alias_match.group("name")
            value = alias_match.group("value")
            flags = alias_match.group("flags") or ""
            is_global = "-g" in flags

            # Clean up the value (unescape quotes)
            value = value.replace("\\'", "'").replace('\\"', '"')

            aliases.append(
                ParsedAlias(
                    name=name,
                    value=value,
                    description=pending_comment,
                    is_global=is_global,
                )
            )
            pending_comment = None
        else:
            # Reset pending comment if we hit a non-comment, non-alias line
            if line.strip() and not line.strip().startswith("#"):
                pending_comment = None

    return aliases


def fetch_omz_plugin(plugin_id: str) -> list[ParsedAlias]:
    """Fetch and parse aliases from an Oh My Zsh plugin."""
    url = f"{OMZ_BASE_URL}/{plugin_id}/{plugin_id}.plugin.zsh"
    try:
        content = fetch_url(url)
        return parse_aliases(content)
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
        print(f"  Warning: Failed to fetch {plugin_id}: {e}")
        return []


def create_curated_json(
    plugin: PluginConfig,
    aliases: list[ParsedAlias],
    omz_commit: str | None = None,
) -> dict[str, Any]:
    """Create a curated collection JSON structure."""
    today = datetime.now(tz=timezone.utc).strftime("%Y-%m-%d")

    return {
        "id": plugin.plugin_id,
        "name": plugin.name,
        "description": plugin.description,
        "version": "1.0.0",
        "syncedAt": today,
        "attribution": {
            "source": "Oh My Zsh",
            "sourceUrl": (f"https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/{plugin.plugin_id}"),
            "license": "MIT",
            "omzCommit": omz_commit,
        },
        "aliases": [
            {
                "name": a.name,
                "value": a.value,
                **({"description": a.description} if a.description else {}),
                **({"global": True} if a.is_global else {}),
            }
            for a in aliases
        ],
    }


def get_omz_latest_commit() -> str | None:
    """Get the latest commit SHA from Oh My Zsh master branch."""
    try:
        url = "https://api.github.com/repos/ohmyzsh/ohmyzsh/commits/master"
        # URL is hardcoded to trusted GitHub API, not user-controlled
        # nosec B310
        # nosemgrep: python.lang.security.audit.dynamic-urllib-use-detected.dynamic-urllib-use-detected
        with urllib.request.urlopen(url, timeout=10) as response:  # noqa: S310 - same as above
            content: bytes = response.read()
            data: dict[str, Any] = json.loads(content.decode("utf-8"))
            sha: str = data.get("sha", "")
            return sha[:7]  # Short SHA
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError):
        return None


def sync_plugin(
    plugin: PluginConfig,
    *,
    dry_run: bool = False,
    omz_commit: str | None = None,
) -> bool:
    """Sync a single OMZ plugin to a curated JSON file."""
    print(f"\nSyncing: {plugin.name} ({plugin.plugin_id})")

    aliases = fetch_omz_plugin(plugin.plugin_id)
    if not aliases:
        print(f"  No aliases found for {plugin.plugin_id}")
        return False

    print(f"  Found {len(aliases)} aliases")

    collection = create_curated_json(plugin, aliases, omz_commit)

    if dry_run:
        print(f"  [DRY RUN] Would write to collections/omz/{plugin.plugin_id}.json")
        return True

    # Ensure output directory exists
    COLLECTIONS_DIR.mkdir(parents=True, exist_ok=True)

    output_path = COLLECTIONS_DIR / f"{plugin.plugin_id}.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(collection, f, indent=2)
        f.write("\n")

    print(f"  Wrote: {output_path.relative_to(REPO_ROOT)}")
    return True


def update_manifest(synced_plugins: Sequence[str], *, dry_run: bool = False) -> None:
    """Update manifest.json to use curated sources for synced plugins."""
    print("\nUpdating manifest.json...")

    with open(MANIFEST_PATH, encoding="utf-8") as f:
        manifest = json.load(f)

    updated_count = 0
    for collection in manifest["collections"]:
        source = collection.get("source", {})
        plugin_id = source.get("pluginId")

        if source.get("type") == "omz-plugin" and plugin_id in synced_plugins:
            # Convert to curated source
            collection["source"] = {
                "type": "curated",
                "path": f"collections/omz/{plugin_id}.json",
            }
            updated_count += 1
            print(f"  Updated: {collection['id']} -> curated")

    if dry_run:
        print(f"  [DRY RUN] Would update {updated_count} collections in manifest.json")
        return

    # Update version to indicate the change
    # Bump patch version
    version_parts = manifest["version"].split(".")
    try:
        version_parts[-1] = str(int(version_parts[-1]) + 1)
        manifest["version"] = ".".join(version_parts)
    except (ValueError, IndexError):
        print(f"  Warning: Could not bump version '{manifest['version']}', skipping")
    manifest["lastUpdated"] = datetime.now(tz=timezone.utc).strftime("%Y-%m-%d")

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")

    print(f"  Updated manifest version to {manifest['version']}")


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Sync Oh My Zsh plugins to curated JSON files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    parser.add_argument(
        "--plugin",
        type=str,
        help="Sync only a specific plugin (by plugin_id)",
    )
    parser.add_argument(
        "--no-manifest",
        action="store_true",
        help="Skip updating manifest.json",
    )
    args = parser.parse_args()

    print("=" * 60)
    print("Oh My Zsh Plugin Sync")
    print("=" * 60)

    if args.dry_run:
        print("\n[DRY RUN MODE - No changes will be made]\n")

    # Get OMZ commit for attribution
    omz_commit = get_omz_latest_commit()
    if omz_commit:
        print(f"Oh My Zsh commit: {omz_commit}")

    # Filter plugins if specific one requested
    plugins_to_sync = PLUGINS
    if args.plugin:
        plugins_to_sync = [p for p in PLUGINS if p.plugin_id == args.plugin]
        if not plugins_to_sync:
            print(f"Error: Unknown plugin '{args.plugin}'")
            print(f"Available plugins: {', '.join(p.plugin_id for p in PLUGINS)}")
            return

    # Sync plugins
    synced: list[str] = []
    for plugin in plugins_to_sync:
        if sync_plugin(plugin, dry_run=args.dry_run, omz_commit=omz_commit):
            synced.append(plugin.plugin_id)

    # Update manifest
    if synced and not args.no_manifest:
        update_manifest(synced, dry_run=args.dry_run)

    print("\n" + "=" * 60)
    print(f"Synced {len(synced)} of {len(plugins_to_sync)} plugins")
    print("=" * 60)


if __name__ == "__main__":
    main()
