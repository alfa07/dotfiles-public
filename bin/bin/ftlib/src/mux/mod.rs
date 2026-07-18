//! Multiplexer abstraction: `ft` drives features through an abstract
//! `Multiplexer` instead of shelling out to a specific tool inline. Today the
//! backends are herdr and tmux; detection picks one at startup.

pub mod herdr;
pub mod tmux;

use anyhow::Result;
use std::path::{Path, PathBuf};

use crate::feature::Feature;
use herdr::Herdr;
use tmux::Tmux;

/// Rolled-up coding-agent state for a container. Only herdr reports this;
/// tmux has no notion of agent state, so it is always `None` there.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AgentStatus {
    Idle,
    Working,
    Blocked,
    Done,
    Unknown,
}

impl AgentStatus {
    pub fn parse(s: &str) -> Self {
        match s {
            "idle" => AgentStatus::Idle,
            "working" => AgentStatus::Working,
            "blocked" => AgentStatus::Blocked,
            "done" => AgentStatus::Done,
            _ => AgentStatus::Unknown,
        }
    }

    /// Short glyph for the cleanup TUI.
    pub fn glyph(self) -> &'static str {
        match self {
            AgentStatus::Idle => "•",
            AgentStatus::Working => "⚙",
            AgentStatus::Blocked => "!",
            AgentStatus::Done => "✓",
            AgentStatus::Unknown => "?",
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            AgentStatus::Idle => "idle",
            AgentStatus::Working => "working",
            AgentStatus::Blocked => "blocked",
            AgentStatus::Done => "done",
            AgentStatus::Unknown => "unknown",
        }
    }
}

/// A running container that holds a feature's agent: a tmux window/session, or
/// a herdr workspace.
#[derive(Debug, Clone)]
pub struct Container {
    /// Stable handle used for focus/close (tmux window id | herdr workspace id).
    pub id: String,
    /// Feature/branch name (tmux window/session name | herdr workspace label).
    pub name: String,
    /// Working directory, when known.
    pub path: Option<PathBuf>,
    /// Human-readable location for the TUI (e.g. "main:2" | "w3").
    pub display: String,
    /// Rolled-up agent state (herdr only).
    pub agent_status: Option<AgentStatus>,
}

/// The operations `ft` needs from a multiplexer. Kept intentionally small: it is
/// exactly the surface the commands use, not a general tmux/herdr wrapper.
#[allow(async_fn_in_trait)] // dispatched via the `Multiplexer` enum, never as `dyn Mux`
pub trait Mux {
    /// Are we currently running inside this multiplexer?
    fn is_inside(&self) -> bool;
    /// All containers this multiplexer knows about, with metadata.
    async fn list(&self) -> Result<Vec<Container>>;
    /// Containers that belong to `feature` (matched by path/name).
    async fn find_for_feature(&self, feature: &Feature) -> Result<Vec<Container>>;
    /// Create a container for the feature at `path` running `launch`, reusing an
    /// existing one if present. Returns true when a new container was created.
    /// Does not change focus.
    async fn ensure(&self, name: &str, path: &Path, launch: &str) -> Result<bool>;
    /// Bring the feature's container to focus, attaching the outer UI when we are
    /// not already inside the multiplexer and `attach_if_outside` is set.
    async fn focus(&self, name: &str, path: &Path, attach_if_outside: bool) -> Result<()>;
    /// Remove a container.
    async fn close(&self, container: &Container) -> Result<()>;
}

/// The selected multiplexer backend.
pub enum Multiplexer {
    Herdr(Herdr),
    Tmux(Tmux),
}

impl Multiplexer {
    /// Pick a backend (context-aware): explicit `FT_MULTIPLEXER` override wins,
    /// then the multiplexer we are already inside, then herdr if installed, else
    /// tmux. Set `FT_DEBUG_MUX` to print the chosen backend to stderr.
    pub fn detect() -> Self {
        let mux = Self::detect_inner();
        if std::env::var_os("FT_DEBUG_MUX").is_some() {
            eprintln!("ft: using {} multiplexer", mux.kind_label());
        }
        mux
    }

    fn detect_inner() -> Self {
        match std::env::var("FT_MULTIPLEXER").ok().as_deref() {
            Some("herdr") => return Multiplexer::Herdr(Herdr::new()),
            Some("tmux") => return Multiplexer::Tmux(Tmux::new()),
            Some(other) if !other.is_empty() => {
                eprintln!(
                    "Warning: ignoring unknown FT_MULTIPLEXER={:?} (expected herdr|tmux)",
                    other
                );
            }
            _ => {}
        }

        if std::env::var("HERDR_ENV").as_deref() == Ok("1") {
            return Multiplexer::Herdr(Herdr::new());
        }
        if std::env::var("TMUX").is_ok() {
            return Multiplexer::Tmux(Tmux::new());
        }
        if binary_on_path("herdr") {
            return Multiplexer::Herdr(Herdr::new());
        }
        Multiplexer::Tmux(Tmux::new())
    }

    pub fn kind_label(&self) -> &'static str {
        match self {
            Multiplexer::Herdr(_) => "herdr",
            Multiplexer::Tmux(_) => "tmux",
        }
    }

    pub fn is_inside(&self) -> bool {
        match self {
            Multiplexer::Herdr(m) => m.is_inside(),
            Multiplexer::Tmux(m) => m.is_inside(),
        }
    }

    pub async fn list(&self) -> Result<Vec<Container>> {
        match self {
            Multiplexer::Herdr(m) => m.list().await,
            Multiplexer::Tmux(m) => m.list().await,
        }
    }

    pub async fn find_for_feature(&self, feature: &Feature) -> Result<Vec<Container>> {
        match self {
            Multiplexer::Herdr(m) => m.find_for_feature(feature).await,
            Multiplexer::Tmux(m) => m.find_for_feature(feature).await,
        }
    }

    pub async fn ensure(&self, name: &str, path: &Path, launch: &str) -> Result<bool> {
        match self {
            Multiplexer::Herdr(m) => m.ensure(name, path, launch).await,
            Multiplexer::Tmux(m) => m.ensure(name, path, launch).await,
        }
    }

    pub async fn focus(&self, name: &str, path: &Path, attach_if_outside: bool) -> Result<()> {
        match self {
            Multiplexer::Herdr(m) => m.focus(name, path, attach_if_outside).await,
            Multiplexer::Tmux(m) => m.focus(name, path, attach_if_outside).await,
        }
    }

    pub async fn close(&self, container: &Container) -> Result<()> {
        match self {
            Multiplexer::Herdr(m) => m.close(container).await,
            Multiplexer::Tmux(m) => m.close(container).await,
        }
    }
}

/// Canonicalize a path for equality comparisons, falling back to the input.
pub(crate) fn canon(path: &Path) -> PathBuf {
    std::fs::canonicalize(path).unwrap_or_else(|_| path.to_path_buf())
}

/// True if an executable named `name` exists on `PATH`.
fn binary_on_path(name: &str) -> bool {
    let Some(paths) = std::env::var_os("PATH") else {
        return false;
    };
    std::env::split_paths(&paths).any(|dir| {
        let candidate = dir.join(name);
        is_executable_file(&candidate)
    })
}

#[cfg(unix)]
fn is_executable_file(path: &Path) -> bool {
    use std::os::unix::fs::PermissionsExt;
    std::fs::metadata(path)
        .map(|m| m.is_file() && m.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

#[cfg(not(unix))]
fn is_executable_file(path: &Path) -> bool {
    path.is_file()
}
