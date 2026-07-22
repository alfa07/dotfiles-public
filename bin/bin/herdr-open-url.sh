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
open_bin="$HOME/.clipcast/bin/open"

log_dir="$HOME/.clipcast/logs"
log="$log_dir/open-log.txt"
mkdir -p "$log_dir"

# Trim the log to its last 1000 lines, same as the tmux binding.
if [ -f "$log" ]; then
    tail -n 1000 "$log" >"$log.tmp" && mv "$log.tmp" "$log"
fi
echo "--- $(date) ---" >>"$log"

notify() {
    local title="$1"
    local body="${2:-}"
    if [ -n "$body" ]; then
        "$herdr" notification show "$title" --body "$body" >/dev/null 2>&1 || true
    else
        "$herdr" notification show "$title" >/dev/null 2>&1 || true
    fi
}

die() {
    local title="$1"
    local body="${2:-}"
    echo "$title${body:+: $body}" >>"$log"
    notify "$title" "$body"
    exit 1
}

# Preflight: clipcast open binary must exist.
if [ ! -x "$open_bin" ]; then
    die "clipcast: open binary missing" "$open_bin not found or not executable"
fi

if [ -z "$pane" ]; then
    die "clipcast: no active pane" "HERDR_ACTIVE_PANE_ID is not set"
fi

notify "opening..."

pane_output=$("$herdr" pane read "$pane" --source recent-unwrapped --lines 200 2>>"$log")
pane_exit=$?
if [ $pane_exit -ne 0 ]; then
    die "clipcast: pane read failed" "herdr pane read exited $pane_exit for pane $pane"
fi

url=$(printf '%s' "$pane_output" \
    | grep -oE "https://[^ ]+" \
    | tail -1 \
    | tr -d "\r")

echo "url: [$url]" >>"$log"

if [ -z "$url" ]; then
    die "clipcast: no url found" "no https:// URL in the last 200 lines of pane $pane"
fi

notify "opening: $url"

if RUST_LOG=info "$open_bin" -na "Google Chrome" \
    --args --profile-directory="Profile 2" "$url" >>"$log" 2>&1; then
    echo "opened ok" >>"$log"
else
    die "clipcast: open failed" "$url — check $log"
fi
