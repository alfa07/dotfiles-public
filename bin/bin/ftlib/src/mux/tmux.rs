//! tmux backend. Preserves the original `ft` tmux behavior exactly: a feature is
//! a window inside the current session when we're already in tmux, or its own
//! session when we're not.

use anyhow::{anyhow, Result};
use std::path::{Path, PathBuf};
use std::process::Stdio;
use tokio::process::Command;

use super::{canon, Container, Mux};
use crate::feature::Feature;

pub struct Tmux;

impl Tmux {
    pub fn new() -> Self {
        Tmux
    }
}

impl Default for Tmux {
    fn default() -> Self {
        Tmux::new()
    }
}

#[derive(Debug, Clone)]
struct TmuxWindow {
    session: String,
    window_index: String,
    window_id: String,
    name: String,
    path: PathBuf,
    ft_worktree: Option<String>,
}

impl TmuxWindow {
    /// The path we treat as this window's worktree: the explicit `@ft-worktree`
    /// stamp when present, else the pane's current path.
    fn worktree_path(&self) -> &Path {
        self.ft_worktree
            .as_deref()
            .map(Path::new)
            .unwrap_or(&self.path)
    }
}

impl Mux for Tmux {
    fn is_inside(&self) -> bool {
        std::env::var("TMUX").is_ok()
    }

    async fn list(&self) -> Result<Vec<Container>> {
        let windows = list_tmux_windows().await?;
        Ok(windows.into_iter().map(window_to_container).collect())
    }

    async fn find_for_feature(&self, feature: &Feature) -> Result<Vec<Container>> {
        let windows = list_tmux_windows().await?;
        let feature_canon = std::fs::canonicalize(&feature.path).ok();

        Ok(windows
            .into_iter()
            .filter(|w| matches_feature(w, feature_canon.as_deref()))
            .map(window_to_container)
            .collect())
    }

    async fn ensure(&self, name: &str, path: &Path, launch: &str) -> Result<bool> {
        if self.is_inside() {
            let windows = list_tmux_windows().await?;
            if windows.iter().any(|w| w.name == name) {
                return Ok(false);
            }
            let current_session = tmux_current_session().await?;
            tmux_new_window(name, path).await?;
            tmux_send_keys(&format!("{}:{}", current_session, name), launch).await?;
            Ok(true)
        } else {
            if tmux_has_session(name).await? {
                return Ok(false);
            }
            tmux_new_session(name, path).await?;
            tmux_send_keys(&format!("{}:0", name), launch).await?;
            Ok(true)
        }
    }

    async fn focus(&self, name: &str, _path: &Path, attach_if_outside: bool) -> Result<()> {
        if self.is_inside() {
            tmux_select_window(name).await
        } else if attach_if_outside {
            tmux_attach_session(name).await
        } else {
            Ok(())
        }
    }

    async fn close(&self, container: &Container) -> Result<()> {
        tmux_kill_window(&container.id).await
    }
}

fn window_to_container(w: TmuxWindow) -> Container {
    let display = format!("{}:{}", w.session, w.window_index);
    let path = Some(w.worktree_path().to_path_buf());
    Container {
        id: w.window_id,
        name: w.name,
        path,
        display,
        agent_status: None,
    }
}

fn matches_feature(w: &TmuxWindow, feature_canon: Option<&Path>) -> bool {
    if let Some(ref ft_path) = w.ft_worktree {
        if let Some(f_canon) = feature_canon {
            if let Ok(stamped) = std::fs::canonicalize(ft_path) {
                return stamped == f_canon;
            }
        }
        return false;
    }

    if let Some(f_canon) = feature_canon {
        if let Ok(window_path_canon) = std::fs::canonicalize(&w.path) {
            if window_path_canon.starts_with(f_canon) {
                return true;
            }
        }
    }

    false
}

async fn tmux_has_session(name: &str) -> Result<bool> {
    let output = Command::new("tmux")
        .arg("has-session")
        .arg("-t")
        .arg(name)
        .output()
        .await?;
    Ok(output.status.success())
}

async fn tmux_current_session() -> Result<String> {
    let output = Command::new("tmux")
        .arg("display-message")
        .arg("-p")
        .arg("#{session_name}")
        .output()
        .await?;

    if !output.status.success() {
        return Err(anyhow!("Failed to get current tmux session"));
    }

    Ok(String::from_utf8(output.stdout)?.trim().to_string())
}

async fn tmux_new_session(name: &str, path: &Path) -> Result<()> {
    let status = Command::new("tmux")
        .arg("new-session")
        .arg("-d")
        .arg("-s")
        .arg(name)
        .arg("-c")
        .arg(path)
        .status()
        .await?;

    if !status.success() {
        return Err(anyhow!("Failed to create tmux session"));
    }

    Ok(())
}

async fn tmux_new_window(name: &str, path: &Path) -> Result<()> {
    let canon = canon(path);

    let output = Command::new("tmux")
        .arg("new-window")
        .arg("-P")
        .arg("-F")
        .arg("#{window_id}")
        .arg("-n")
        .arg(name)
        .arg("-c")
        .arg(&canon)
        .output()
        .await?;

    if !output.status.success() {
        return Err(anyhow!("Failed to create tmux window"));
    }

    let window_id = String::from_utf8(output.stdout)?.trim().to_string();
    if !window_id.is_empty() {
        let _ = Command::new("tmux")
            .arg("set-option")
            .arg("-w")
            .arg("-t")
            .arg(&window_id)
            .arg("@ft-worktree")
            .arg(canon.to_string_lossy().as_ref())
            .status()
            .await;
    }

    Ok(())
}

async fn tmux_attach_session(name: &str) -> Result<()> {
    let status = Command::new("tmux")
        .arg("attach-session")
        .arg("-t")
        .arg(name)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .await?;

    if !status.success() {
        return Err(anyhow!("Failed to attach to tmux session"));
    }

    Ok(())
}

async fn tmux_select_window(name: &str) -> Result<()> {
    let status = Command::new("tmux")
        .arg("select-window")
        .arg("-t")
        .arg(name)
        .status()
        .await?;

    if !status.success() {
        return Err(anyhow!("Failed to select tmux window"));
    }

    Ok(())
}

async fn tmux_send_keys(target: &str, keys: &str) -> Result<()> {
    let status = Command::new("tmux")
        .arg("send-keys")
        .arg("-t")
        .arg(target)
        .arg(keys)
        .arg("Enter")
        .status()
        .await?;

    if !status.success() {
        return Err(anyhow!("Failed to send keys to tmux"));
    }

    Ok(())
}

async fn list_tmux_windows() -> Result<Vec<TmuxWindow>> {
    let output = Command::new("tmux")
        .arg("list-windows")
        .arg("-a")
        .arg("-F")
        .arg("#{session_name}:#{window_index}\t#{window_id}\t#{window_name}\t#{pane_current_path}\t#{@ft-worktree}")
        .output()
        .await?;

    if !output.status.success() {
        return Ok(Vec::new());
    }

    let stdout = String::from_utf8(output.stdout)?;
    let mut windows = Vec::new();

    for line in stdout.lines() {
        let parts: Vec<&str> = line.split('\t').collect();
        if parts.len() >= 4 {
            let session_window: Vec<&str> = parts[0].split(':').collect();
            if session_window.len() == 2 {
                let ft_worktree = parts
                    .get(4)
                    .map(|s| s.to_string())
                    .filter(|s| !s.is_empty());
                windows.push(TmuxWindow {
                    session: session_window[0].to_string(),
                    window_index: session_window[1].to_string(),
                    window_id: parts[1].to_string(),
                    name: parts[2].to_string(),
                    path: PathBuf::from(parts[3]),
                    ft_worktree,
                });
            }
        }
    }

    Ok(windows)
}

async fn tmux_kill_window(target: &str) -> Result<()> {
    let status = Command::new("tmux")
        .arg("kill-window")
        .arg("-t")
        .arg(target)
        .status()
        .await?;

    if !status.success() {
        return Err(anyhow!("Failed to kill tmux window"));
    }

    Ok(())
}
