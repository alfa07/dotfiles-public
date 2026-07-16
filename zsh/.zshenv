. "$HOME/.cargo/env"

# Headless Xvfb on :99 is always-on (started at boot).
# Export here so every zsh (including new tmux client attaches) carries DISPLAY,
# which prevents tmux update-environment from recording `-DISPLAY` at the session level.
export DISPLAY=:99
