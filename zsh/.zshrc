# typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
SCRIPT_DIR=$(cd "$(dirname "${(%):-%x}")" && pwd)

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

function command_exists() {
  command -v "$1" >/dev/null 2>&1 && "$1" "$2" >/dev/null 2>&1
}

# zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export PATH=$PATH:$HOME/dev/roc/roc_nightly-macos_apple_silicon-2025-09-09-d73ea109cc2

# python3 console scripts (e.g. pybritive, used by s/aws-creds) get installed
# into the framework interpreter's bin, which isn't on PATH by default. Ask
# python3 for it so this tracks whatever version is active.
if command -v python3 >/dev/null 2>&1; then
  _py3_scripts=$(python3 -c 'import sysconfig; print(sysconfig.get_path("scripts"))' 2>/dev/null)
  [[ -n "$_py3_scripts" && -d "$_py3_scripts" ]] && export PATH="$_py3_scripts:$PATH"
  unset _py3_scripts
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

plugins=(
  git
  dotenv
  # kubectl-autocomplete
  zsh-cargo-completion
  zsh-vi-mode
  # should be last
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

source $HOME/.config/broot/launcher/bash/br

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/zsh_completion" ] && \. "$NVM_DIR/zsh_completion"  # This loads nvm bash_completion

if [[ "$(uname -s)" == "Linux" ]]; then
   # echo "Linux"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  export PYENV_ROOT="$HOME/.pyenv"
  eval "$(pyenv init -)"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
  # [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  # source ~/.zsh-base/fzf.zsh
  alias pbcopy="xclip -in -sel clip"
  alias pbpaste="xclip -out -sel clip"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PYENV_ROOT="$HOME/.pyenv"
  eval "$(pyenv init -)"
   # echo "macOS"
  export PATH=$HOME/.local/bin:$PATH
  # pnpm
  export PNPM_HOME="$HOME/Library/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
  # pnpm end
fi

source $HOME/.config/broot/launcher/bash/br
export EDITOR=nvim
# echo "script dir" $SCRIPT_DIR

if [[ -e ~/.secrets-obs ]]; then
  source ~/.secrets-obs
fi

# Check if the SSH agent is running
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "agent is not running, starting..."
    eval "$(ssh-agent -s)"
fi

# Check if the private key is already added to the agent
if [[ -e ~/.ssh/id_rsa ]]; then
  local name=$(cat ~/.ssh/id_rsa.pub | awk '{ print $3 }')
  if ! (ssh-add -l | grep -q "$name"); then
      echo "no id_rsa key, adding..."
      ssh-add ~/.ssh/id_rsa
  fi
fi

CARGO_NET_GIT_FETCH_WITH_CLI=true

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/maxim/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/maxim/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/Users/maxim/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/maxim/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup

if [ -f "/Users/maxim/miniforge3/etc/profile.d/mamba.sh" ]; then
    . "/Users/maxim/miniforge3/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

# Go lang
export PATH="$HOME/go/bin:/usr/local/go/bin:$PATH"

# Flux
command -v flux >/dev/null && . <(flux completion zsh)

# Kubernetes
alias k=kubectl
fpath=($ZSH/completions $fpath)
if [[ -e ~/.zfunc ]]; then
  fpath+=~/.zfunc
fi
autoload -U compinit && compinit

# alias k=kubectl
# compdef k=kubectl
# source <(kubectl completion zsh)

# prevent zsh from eating space before '|'
setopt NO_AUTO_PARAM_SLASH

export AIDER_LIGHT_MODE="true"

# we use git-crypt
# After cloning the repository
# git-crypt unlock /path/to/git-crypt-key
if [[ -e ~/.secrets ]]; then
  source ~/.secrets
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi
if command -v gh &> /dev/null; then
  eval "$(gh completion -s zsh)"
fi
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
# zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
# source <(carapace _carapace)
eval "$(atuin init zsh)"
zvm_after_init_commands+=("bindkey '^r' _atuin_search_widget")

if [[ -e /usr/local/texlive/2024/bin/universal-darwin ]]; then
  export PATH="/usr/local/texlive/2024/bin/universal-darwin:$PATH"
fi

if [[ -e ~/kube/microk8s-config ]]; then
  export KUBECONFIG=~/.kube/microk8s-config
fi

# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r "$HOME/.opam/opam-init/init.zsh" ]] || source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null
# END opam configuration

# [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# yazi file manager integration
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Fix for bat to display correct colors in neovim
# https://github.com/sharkdp/bat/issues/634#issuecomment-524453561
if [ -n "${NVIM_LISTEN_ADDRESS+x}" ]; then
  export COLORTERM="truecolor"
fi

# Set solarized-light colors for FZF
export FZF_DEFAULT_OPTS='
  --color=bg+:#eee8d5,bg:#fdf6e3,spinner:#719e07,hl:#719e07
  --color=fg:#657b83,header:#586e75,info:#93a1a1,pointer:#719e07
  --color=marker:#719e07,fg+:#073642,prompt:#719e07,hl+:#719e07'

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/maxim/.cache/lm-studio/bin"
# End of LM Studio CLI section
#
if [[ -e ~/kube/microk8s-config ]]; then
  export KUBECONFIG=~/.kube/microk8s-config
fi


function wez_notify() {
  title=$1
  message=$2
  printf "\033]777;notify;%s;%s\033\\" "$title" "$message"
}

if [[ -e /Applications/love.app ]]; then
  alias love="/Applications/love.app/Contents/MacOS/love"
fi

# sfid
if command -v sf &> /dev/null; then
  eval "$(sf aliases)"
fi

## gcloud (macOS/Homebrew only — inert elsewhere)
if [[ -e /opt/homebrew/bin/gcloud ]]; then
  [[ -x /usr/local/bin/python3.11 ]] && export CLOUDSDK_PYTHON=/usr/local/bin/python3.11
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

# clipcast
export PATH="$HOME/.clipcast/bin:$PATH"

# elixir env manager for Symphony
if [[ -e $HOME/.local/bin/mise ]]; then
  eval "$($HOME/.local/bin/mise activate zsh)"
fi

# [[ SHOULD BE LAST ]]
# Automatically switch to tmux session if exists
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]]; then
    # if tmux ls &>/dev/null; then
    #     exec tmux attach -d
    # fi
    # SESSION="${LC_TMUX_SESSION:-observe}"
    # tmux new-session -As "$SESSION"
fi
