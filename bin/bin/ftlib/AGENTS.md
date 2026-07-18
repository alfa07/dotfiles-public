# AGENTS.md — ftlib

Implementation crate behind the `~/bin/ft` rust-script. `ft` manages git
feature-clones under `<repo>/.wt/` (each on its own branch) and gives each one a
terminal container running Claude Code, through a pluggable multiplexer backend.

## Rebuild after editing this crate (do this every time)

rust-script caches the compiled `ft` binary keyed on the **script file**
(`~/bin/ft`), not on this path-dependency. After changing anything under
`~/bin/ftlib/`, a plain `ft` run keeps executing the **stale** cached build.
Always force a rebuild so your changes take effect:

```bash
rust-script --force ~/bin/ft --help
```

Run this after every edit to `~/bin/ftlib/`. It recompiles against the current
crate and leaves a fresh cache; subsequent normal `ft` runs are fast and current
until the next edit. (`rust-script --clear-cache` also works.)

## Layout

```
~/bin/ft                     # thin rust-script: fn main() { ftlib::run() }
~/bin/ftlib/
  src/
    lib.rs          # run() -> ExitCode; owns #[tokio::main] + command dispatch
    cli.rs          # clap Cli/Commands
    feature.rs      # Feature/FeatureKind/FeatureStatus/PrInfo/CiStatus/... (pure data)
    git.rs          # git + gh helpers: repo discovery, clone, status, PR/CI, stale branches
    cargo_setup.rs  # per-feature cargo target-dir / sccache / /scratch seeding
    commands.rs     # cmd_new/go/clean/restore/clean_stale_branches
    tui.rs          # skim fuzzy finder + ratatui cleanup checklist
    mux/
      mod.rs        # Mux trait, Container, AgentStatus, Multiplexer enum + detect()
      tmux.rs       # tmux backend
      herdr.rs      # herdr backend
```

## Multiplexer abstraction

`ft` never shells out to tmux/herdr inline. It goes through
`mux::Multiplexer` (`enum { Herdr(Herdr), Tmux(Tmux) }`), which delegates to a
shared `Mux` trait: `is_inside`, `list`, `find_for_feature`, `ensure`, `focus`,
`close`. A `Container` is a tmux window/session or a herdr workspace.

Backend chosen by `Multiplexer::detect()` (context-aware):

1. `FT_MULTIPLEXER=herdr|tmux` — explicit override
2. inside a session — `$HERDR_ENV=1` → herdr, `$TMUX` → tmux
3. `herdr` on `PATH` → herdr
4. otherwise → tmux

Set `FT_DEBUG_MUX=1` to print the chosen backend to stderr.

- **herdr**: a feature = one *workspace* (label = branch, cwd = clone path) with
  `claude` in its root pane (`workspace create` + `pane run`). Matches herdr's
  "one workspace per task" model and keeps a readable per-feature state rollup
  with many features in flight. Workspaces carry no cwd in the CLI JSON, so
  `list` joins `api snapshot` workspaces → their pane's cwd for path matching.
- **tmux**: unchanged from the original `ft` — a window in the current session
  when inside tmux, or a dedicated session when not; stamps `@ft-worktree`.

When adding a backend method, add it to the `Mux` trait, implement it in both
`tmux.rs` and `herdr.rs`, and add a matching delegating method on the
`Multiplexer` enum in `mod.rs`.

### herdr CLI facts (0.7.x)

- `herdr api snapshot` → `{result:{snapshot:{workspaces,panes,agents,...}}}`.
- `herdr workspace create --cwd P --label L --no-focus` →
  `{result:{workspace:{workspace_id,...}, root_pane:{pane_id}, ...}}`.
- `herdr pane run <pane> <cmd>`, `workspace focus`, `workspace close` succeed
  **silently** (no JSON body) — use `herdr_ok` (checks exit status), not
  `herdr_json`, for those. Use `herdr_json` only for `api snapshot` and
  `workspace create`, whose output we parse.
- cwd values are canonicalized by herdr (`/tmp` → `/private/tmp`), so compare
  paths with `mux::canon` on both sides.

## Conventions

- No `unwrap()` in new code; return `anyhow::Result` and let `run()` print/exit.
- Git/clone/status/cleanup logic is a verbatim port of the original single-file
  `ft` — keep it behavior-preserving; the multiplexer is the only new seam.
- Interactive/attach paths (`focus` outside a session: herdr execs the UI, tmux
  `attach-session`) block on a real terminal and can't be driven non-interactively.

## Build / lint / verify

```bash
cd ~/bin/ftlib
cargo build
cargo clippy --all-targets      # keep clean
rust-script --force ~/bin/ft --help   # make `ft` reflect your changes
```

End-to-end herdr check without launching a real agent: create a throwaway git
repo with a bare origin, put a stub `claude` on `PATH`, run with
`HERDR_ENV=1 FT_MULTIPLEXER=herdr` (so `focus` doesn't block on a UI attach),
then close the created workspace(s) with `herdr workspace close <id>`.
