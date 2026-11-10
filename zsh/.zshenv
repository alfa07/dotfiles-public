# lmod (sourced by the bash login on Meta devservers) exports
# FPATH=/usr/share/lmod/lmod/init/ksh_funcs; a zsh started from bash inherits it
# *instead of* its default fpath, so compinit/bashcompinit vanish and startup
# hangs in the command_not_found_handler. Restore the defaults (inert elsewhere).
if (( ! ${fpath[(I)*/zsh/$ZSH_VERSION/functions]} )); then
  for _d in /usr/local/share/zsh/site-functions /usr/share/zsh/site-functions \
            /usr/share/zsh/$ZSH_VERSION/functions; do
    [[ -d $_d ]] && fpath+=($_d)
  done
  unset _d
fi

[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

if [[ -r /usr/facebook/ops/rc/master.zshrc ]]; then
  # Meta devserver: never sync shell history to the Atuin server.
  # Env override (ATUIN_<setting>) beats ~/.config/atuin/config.toml.
  export ATUIN_AUTO_SYNC=false
else
  # Headless Xvfb on :99 is always-on (started at boot).
  # Export here so every zsh (including new tmux client attaches) carries DISPLAY,
  # which prevents tmux update-environment from recording `-DISPLAY` at the session level.
  export DISPLAY=:99
fi
