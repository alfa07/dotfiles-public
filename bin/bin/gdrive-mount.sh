#!/usr/bin/env bash
# Portable Google Drive mount wrapper.
# Finds and runs gdrive-mount-systemd.sh from the plugin.
# Copy this to ~/bin/gdrive-mount.sh — it stays thin and never needs updating.

set -euo pipefail

if [[ "$(uname)" != "Linux" ]]; then
    echo "gdrive-mount: Linux only. On Mac, use Google Drive for Desktop." >&2
    exit 1
fi

# Find the mount script from plugin cache or installed marketplace
script=$(find "$HOME/.claude/plugins/cache" -path "*/gdrive-mount/*/bin/gdrive-mount-systemd.sh" 2>/dev/null | sort -V | tail -1 || true)
[ -z "$script" ] && script="/home/maxim/.claude/agent-market/plugins/gdrive-mount/bin/gdrive-mount-systemd.sh"

if [[ -f "$script" ]]; then
    exec bash "$script" "$@"
else
    echo "gdrive-mount: plugin not found. Install it with: claude-templates plugin gdrive-mount install" >&2
    exit 1
fi
