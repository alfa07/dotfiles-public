#!/usr/bin/env bash
# herdr port of the tmux `bind y` clipcast opener.
#
# Grabs the last https URL, file:// URI, or local file path from the focused
# pane and opens it on the Mac via clipcast-open: https URLs open in Chrome
# "Profile 2"; local files open in the Snowflake profile ("Profile 1"). Wired up
# from config.toml as a `type = "shell"` custom command keybinding, which
# exports HERDR_ACTIVE_PANE_ID and HERDR_BIN_PATH. Replaces the tmux version's
# `capture-pane -p -J` with `herdr pane read --source recent-unwrapped`
# (unwrapped == the -J analog, so a soft-wrapped URL is not split across lines).

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

if [ -z "$pane" ]; then
    die "clipcast: no active pane" "HERDR_ACTIVE_PANE_ID is not set"
fi

notify "opening..."

pane_output=$("$herdr" pane read "$pane" --source recent-unwrapped --lines 200 2>>"$log")
pane_exit=$?
if [ $pane_exit -ne 0 ]; then
    die "clipcast: pane read failed" "herdr pane read exited $pane_exit for pane $pane"
fi

# Match the last https URL, file:// URI, or local file path (absolute, ~/, or
# ./|../ relative) ending in a clipcast-openable extension. The https branch
# must end on a URL-safe char ([A-Za-z0-9/=&%#_~+@-]) so trailing prose
# punctuation captured by the terminal (e.g. ":", ".", ")", quotes) is not
# treated as part of the URL. URL/file:// branches come first so a path's
# leading "/" never steals the "//" inside a scheme.
exts="html?|pdf|png|jpe?g|gif|webp|svg|txt|md|csv|json|log|mp4|mov|mp3|wav|zip"
url=$(printf '%s' "$pane_output" \
    | grep -oiE "https?://[^[:space:]]*[A-Za-z0-9/=&%#_~+@-]|file://[^[:space:]]+|(\.{1,2}/|~?/)[^[:space:]]*\.($exts)" \
    | tail -1 \
    | tr -d "\r")

echo "url: [$url]" >>"$log"

if [ -z "$url" ]; then
    die "clipcast: nothing found" "no URL or file path in the last 200 lines of pane $pane"
fi

# Relative targets (./x, ../x) resolve against the focused pane's working dir.
pane_cwd=$("$herdr" pane get "$pane" 2>>"$log" \
    | grep -oE '"foreground_cwd":"[^"]*"' \
    | head -1 \
    | sed 's/^"foreground_cwd":"//; s/"$//')
[ -n "$pane_cwd" ] || pane_cwd="$HOME"

notify "opening: $url"

if "$(dirname "$0")/clipcast-open" "$url" "$pane_cwd" >>"$log" 2>&1; then
    echo "opened ok" >>"$log"
else
    die "clipcast: open failed" "$url — check $log"
fi
