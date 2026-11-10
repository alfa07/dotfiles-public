# Meta devserver setup. Sourced from ~/.zshrc only when
# /usr/facebook/ops/rc/master.zshrc exists (IS_META=1).
# Mirrors the stock Meta ~/.zshrc that stowing ours replaces.

# Load Facebook stuff (the stock rc says: don't remove this line).
source /usr/facebook/ops/rc/master.zshrc

# Keep oodles of command history (see https://fburl.com/zshhistory).
HISTSIZE=1000000
SAVEHIST=1000000
setopt APPEND_HISTORY

# Allow tab completion in the middle of a word.
setopt COMPLETE_IN_WORD

# Safer 'sudo rm' for interactive sessions (from the stock Meta rc).
if [[ -o interactive ]]; then
  sudo() {
    if [ "$1" = "rm" ]; then
      shift
      command sudo rm --preserve-root=all --one-file-system "$@"
    else
      command sudo "$@"
    fi
  }
fi
