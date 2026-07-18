# ftlib

Implementation crate behind the `~/bin/ft` rust-script. `ft` manages git
feature-clones under `<repo>/.wt/` and gives each one a terminal container
running Claude Code, via a pluggable multiplexer backend.

## Multiplexer

`ft` drives features through `mux::Multiplexer` (`enum { Herdr, Tmux }`), chosen
at startup by `Multiplexer::detect()`:

1. `FT_MULTIPLEXER=herdr|tmux` — explicit override
2. inside a session — `$HERDR_ENV=1` → herdr, `$TMUX` → tmux
3. `herdr` on `PATH` → herdr
4. otherwise → tmux

- **herdr**: each feature is a *workspace* (label = branch, cwd = clone path)
  with `claude` launched in its root pane. Matches herdr's "one workspace per
  task" model; keeps a readable per-feature state rollup with many features.
- **tmux**: unchanged from the original `ft` — a window in the current session
  when inside tmux, or a dedicated session when not.

## Editing this crate (important)

rust-script caches the compiled `ft` binary keyed on the **script file**, not on
this path-dependency. After editing anything under `ftlib/`, a plain `ft` run
will keep executing the **stale** cached build. Pick up your changes with:

```bash
rust-script --force ~/bin/ft <args>   # rebuild once, then normal runs are cached
# or
rust-script --clear-cache             # drop the cache entirely
```

Normal (unchanged-library) runs are cached and start fast; no action needed.

Standalone build/lint while developing:

```bash
cd ~/bin/ftlib && cargo build && cargo clippy --all-targets
```
