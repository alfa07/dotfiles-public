#!/usr/bin/env bash
# herdr port of the tmux `bind y` clipcast opener.
#
# Grabs the last https URL from the focused pane and opens it in Chrome
# "Profile 2" via the clipcast opener. Wired up from config.toml as a
# `type = "shell"` custom command keybinding, which exports HERDR_ACTIVE_PANE_ID
# and HERDR_BIN_PATH. Replaces the tmux version's `capture-pane -p -J` with
# `herdr pane read --source recent-unwrapped` (unwrapped == the -J analog, so a
# soft-wrapped URL is not split across lines).

set -u

herdr="${HERDR_BIN_PATH:-herdr}"
pane="${HERDR_ACTIVE_PANE_ID:-}"

log_dir="$HOME/.clipcast/logs"
log="$log_dir/open-log.txt"
mkdir -p "$log_dir"

# Trim the log to its last 1000 lines, same as the tmux binding.
if [ -f "$log" ]; then
    tail -n 1000 "$log" >"$log.tmp" && mv "$log.tmp" "$log"
fi
echo "--- $(date) ---" >>"$log"

notify() {
    "$herdr" notification show "$1" >>"$log" 2>&1 || true
}

if [ -z "$pane" ]; then
    echo "no HERDR_ACTIVE_PANE_ID in environment" >>"$log"
    notify "clipcast: no active pane"
    exit 1
fi

notify "opening..."

url=$("$herdr" pane read "$pane" --source recent-unwrapped --lines 200 2>>"$log" \
    | grep -oE "https://[^ ]+" \
    | tail -1 \
    | tr -d "\r")

echo "url: [$url]" >>"$log"

if [ -z "$url" ]; then
    notify "clipcast: no url found"
    echo "no url" >>"$log"
    exit 0
fi

notify "opening: $url"

if RUST_LOG=info "$HOME/.clipcast/bin/open" -na "Google Chrome" \
    --args --profile-directory="Profile 2" "$url" >>"$log" 2>&1; then
    echo "opened ok" >>"$log"
else
    echo "open failed" >>"$log"
    notify "clipcast: open failed"
fi
