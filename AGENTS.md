# Dotfiles

My personal dotfiles managed with GNU Stow.

> `AGENTS.md` is the canonical copy of this file; `README.md` and `CLAUDE.md`
> are symlinks to it — edit `AGENTS.md`. Run `bin/bin/enforce-agents-md` to
> restore the `CLAUDE.md -> AGENTS.md` symlink invariant across the repo.

## Prerequisites

- [GNU Stow](https://www.gnu.org/software/stow/)
- [Git](https://git-scm.com/)

## Installation

1. Clone the repository:

```bash
git clone git@github.com:alfa07/dotfiles5.git ~/.dotfiles
cd ~/.dotfiles
```

2. Install configurations using stow:

```bash
# Install all configurations
stow */

# Or install specific configurations
stow nvim
stow tmux
stow fish
# etc...
```

Codex keeps generated machine state in `~/.codex/config.toml`, so its tracked
preferences are merged rather than stowed over that file:

```bash
sync-codex-config
```

## Git hooks

This repo ships commit hooks in `.githooks/` that enforce the commit identity
and block `Co-Authored-By:` trailers. Git does not run tracked hooks on clone
(that would be a security hole), so enable them once per clone:

```bash
git config --local core.hooksPath .githooks
```

Once enabled:

- **`pre-commit`** rejects the commit unless the author *and* committer email
  are `maximsok@gmail.com`. On mismatch it prints the fix:
  `git config --local user.name "Maxim Sokolov" && git config --local user.email "maximsok@gmail.com"`.
- **`commit-msg`** rejects any message containing a `Co-Authored-By:` trailer.

The hooks are repo-local on purpose — a global hook would break commits made
under other identities (e.g. work repos).

## Multi-machine sync workflow

These dotfiles are shared across several machines/locations. `main` is the
shared trunk; each machine tracks its own **per-location branch** (e.g.
`mac-obs`, `mac-local`, `linux`, `obs-remote`) and never commits to `main`
directly.

- **Save local work:** commit on the machine's own location branch and push it
  (`git push`). Each machine only ever pushes to its own branch.
- **Publish to the trunk:** merge the location branch into `main`
  (`git checkout main && git merge <location-branch>`), then push `main`.
- **Pull shared changes onto a machine:** merge `main` into that machine's
  location branch (`git merge origin/main`). Never `git reset --hard main` from
  a location branch — `--hard` discards that branch's own commits.

### Gating location-specific changes

A location branch may contain changes that only make sense on that machine
(macOS-only, Linux-only, one specific host). Before such a change reaches
`main` it must be safe to run everywhere:

- **Machine-specific file** (only stowed/used on one OS, e.g. `karabiner` on
  macOS): fine as-is — it simply isn't installed elsewhere.
- **Common/shared file** that every machine sources or reads (`zsh/.zshrc`,
  `zsh/.zshenv`, `zsh/.zsh/aliases`, `tmux/.tmux.conf`, `git/.gitconfig`, …):
  the change **must be guarded by a runtime check** so it is inert on other
  machines. Do not merge an unguarded OS-specific line into a shared file.

Guarding examples:

```bash
# zsh / bash — shared rc files
case "$(uname -s)" in
  Darwin) export HOMEBREW_PREFIX=/opt/homebrew ;;
  Linux)  export HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew ;;
esac

# gate on a specific host
[[ "$(hostname -s)" == "obs-remote" ]] && export FOO=bar
```

```tmux
# tmux — shared .tmux.conf
if-shell 'uname | grep -q Darwin' 'set -g @something "mac-value"'
```

```gitconfig
# git — shared .gitconfig, gate on OS via includeIf or conditional include
[includeIf "gitdir:~/"]
    path = ~/.gitconfig.local
```

Keep the guard next to the change so the intent is obvious at the merge.

## Components

Each top-level directory is a Stow package. Packages suffixed `-mac`/`-macos`
or `-linux` are stowed only on that platform — see the sync workflow above for
how per-machine differences are handled.

- **atuin**: Shell history sync
- **bin**: Custom scripts and executables (e.g. `ft`, `enforce-agents-md`)
- **broot**: Directory navigation
- **claude**: Claude Code configuration and global instructions (`~/.claude`)
- **codex**: Portable Codex preferences and hooks (`~/.codex`); apply the
  preference template with `sync-codex-config`
- **fish**: Fish shell configuration
- **font-patcher**: Nerd Fonts `font-patcher` tool
- **fonts**: Custom fonts
- **fzf**: Fuzzy finder configuration
- **gh**: GitHub CLI configuration
- **ghostty**: Ghostty terminal configuration
- **git**: Git configuration (`.gitconfig`)
- **gitui**: GitUI client configuration
- **helix**: Helix editor configuration
- **htop**: System monitor configuration
- **karabiner**: Keyboard customization (macOS)
- **kitty**: Kitty terminal configuration
- **lazygit**: Lazygit TUI configuration (shared)
- **lazygit-linux**: Lazygit overrides (Linux only)
- **lazygit-mac**: Lazygit overrides (macOS only)
- **lazyvim**: LazyVim Neovim configuration
- **lf**: `lf` file manager configuration
- **lvim**: LunarVim configuration
- **nnn**: `nnn` file manager configuration
- **nu-addons**: Nushell add-ons (e.g. atuin init)
- **nushell**: Nushell configuration
- **nushell-macos**: Nushell configuration (macOS only)
- **nvim**: Neovim configuration
- **ohmyzsh-custom**: Oh My Zsh custom plugins and themes
- **p10k**: Powerlevel10k Zsh prompt configuration
- **secrets**: git-crypt-encrypted shell secrets (see [Secrets](#secrets))
- **starship**: Starship prompt configuration
- **tmux**: Terminal multiplexer configuration
- **wezterm**: WezTerm terminal configuration
- **zellij**: Terminal multiplexer configuration
- **zsh**: Zsh shell configuration
- **zsh-base**: Shared base Zsh snippets (e.g. fzf integration)

## Secrets

The `secrets` package (`~/.secrets`) is encrypted at rest with
[git-crypt](https://github.com/AGWA/git-crypt). `.gitattributes` routes it
through the git-crypt filter:

```
secrets/* filter=git-crypt diff=git-crypt
```

Cloning without the key works fine — `secrets/.secrets` just stays an
encrypted blob. To read/edit the plaintext on a new machine, unlock once with
the git-crypt key:

```bash
git-crypt unlock            # if the symmetric key is already in your keyring
git-crypt unlock /path/to/dotfiles.key
```

Never move a secret into a non-`secrets/` file expecting encryption — the
git-crypt rule is path-scoped, not content-scoped.

## License

MIT

## Author

Maxim Sokolov
