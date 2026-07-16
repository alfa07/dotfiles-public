#!/bin/sh
# tmux wrapper for arrange-displays.applescript.
# On success: brief status-line message. On error: a popup that waits for a key.
err=/tmp/arrange-displays.err
if out=$(osascript "$HOME/bin/arrange-displays.applescript" 2>"$err"); then
    tmux display-message "$out"
else
    tmux display-popup -E "echo 'arrange-displays error:'; echo; tail -n1 '$err'; echo; printf 'Press any key to dismiss'; stty -echo; dd bs=1 count=1 >/dev/null 2>&1; stty echo"
fi
