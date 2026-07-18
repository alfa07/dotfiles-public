//! herdr backend. A feature maps to a herdr *workspace* (label = branch,
//! cwd = clone path) with `claude` launched in its root pane. This matches
//! herdr's "one workspace per task" model and keeps a readable per-feature
//! state rollup in the sidebar even with many features in flight.
//!
//! Coded against the herdr 0.7.x CLI JSON surface:
//!   - `herdr api snapshot`      -> {result:{snapshot:{workspaces,panes,agents}}}
//!   - `herdr workspace create`  -> {result:{workspace:{workspace_id,label},root_pane:{pane_id}}}
//!   - `herdr workspace focus/close`, `herdr pane run <pane> <cmd>`
//!
//! Workspaces carry no cwd, so we join workspace -> its pane's cwd for matching.

use anyhow::{anyhow, Context, Result};
use std::path::Path;
use std::process::Stdio;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;
use tokio::process::Command;

use super::{canon, AgentStatus, Container, Mux};
use crate::feature::Feature;

pub struct Herdr {
    /// Set once we've confirmed (or started) a running server this run.
    bootstrapped: AtomicBool,
}

impl Herdr {
    pub fn new() -> Self {
        Herdr {
            bootstrapped: AtomicBool::new(false),
        }
    }

    /// Ensure a herdr server is reachable, starting a headless one if needed.
    async fn ensure_server(&self) -> Result<()> {
        if self.bootstrapped.load(Ordering::Relaxed) {
            return Ok(());
        }
        if server_running().await {
            self.bootstrapped.store(true, Ordering::Relaxed);
            return Ok(());
        }

        // Start a detached headless server. Dropping the child does not kill it
        // (kill_on_drop defaults to false), so it survives after `ft` exits.
        Command::new("herdr")
            .arg("server")
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
            .context("failed to start `herdr server`")?;

        for _ in 0..50 {
            tokio::time::sleep(Duration::from_millis(100)).await;
            if server_running().await {
                self.bootstrapped.store(true, Ordering::Relaxed);
                return Ok(());
            }
        }
        Err(anyhow!("herdr server did not become ready"))
    }

    /// Snapshot every workspace as a Container, joining panes for cwd.
    async fn containers(&self) -> Result<Vec<Container>> {
        let result = herdr_json(&["api", "snapshot"]).await?;
        let snapshot = result
            .get("snapshot")
            .ok_or_else(|| anyhow!("herdr api snapshot: missing `snapshot`"))?;

        // workspace_id -> first pane cwd (ft workspaces have a single pane).
        let mut ws_cwd: std::collections::HashMap<String, String> = std::collections::HashMap::new();
        if let Some(panes) = snapshot.get("panes").and_then(|p| p.as_array()) {
            for pane in panes {
                let (Some(wsid), Some(cwd)) = (
                    pane.get("workspace_id").and_then(|v| v.as_str()),
                    pane.get("cwd").and_then(|v| v.as_str()),
                ) else {
                    continue;
                };
                ws_cwd.entry(wsid.to_string()).or_insert_with(|| cwd.to_string());
            }
        }

        let mut containers = Vec::new();
        if let Some(workspaces) = snapshot.get("workspaces").and_then(|w| w.as_array()) {
            for ws in workspaces {
                let Some(id) = ws.get("workspace_id").and_then(|v| v.as_str()) else {
                    continue;
                };
                let name = ws.get("label").and_then(|v| v.as_str()).unwrap_or(id);
                let agent_status = ws
                    .get("agent_status")
                    .and_then(|v| v.as_str())
                    .map(AgentStatus::parse);
                let path = ws_cwd.get(id).map(std::path::PathBuf::from);
                containers.push(Container {
                    id: id.to_string(),
                    name: name.to_string(),
                    path,
                    display: id.to_string(),
                    agent_status,
                });
            }
        }
        Ok(containers)
    }

    /// Find the workspace whose (root pane) cwd matches `path`.
    async fn find_by_path(&self, path: &Path) -> Result<Option<Container>> {
        let target = canon(path);
        Ok(self
            .containers()
            .await?
            .into_iter()
            .find(|c| c.path.as_deref().map(canon).as_deref() == Some(target.as_path())))
    }
}

impl Default for Herdr {
    fn default() -> Self {
        Herdr::new()
    }
}

impl Mux for Herdr {
    fn is_inside(&self) -> bool {
        std::env::var("HERDR_ENV").as_deref() == Ok("1")
    }

    async fn list(&self) -> Result<Vec<Container>> {
        self.ensure_server().await?;
        self.containers().await
    }

    async fn find_for_feature(&self, feature: &Feature) -> Result<Vec<Container>> {
        self.ensure_server().await?;
        Ok(self.find_by_path(&feature.path).await?.into_iter().collect())
    }

    async fn ensure(&self, name: &str, path: &Path, launch: &str) -> Result<bool> {
        self.ensure_server().await?;

        if self.find_by_path(path).await?.is_some() {
            return Ok(false);
        }

        let path_str = canon(path).to_string_lossy().to_string();
        let created = herdr_json(&[
            "workspace",
            "create",
            "--cwd",
            &path_str,
            "--label",
            name,
            "--no-focus",
        ])
        .await?;

        let pane_id = created
            .get("root_pane")
            .and_then(|p| p.get("pane_id"))
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow!("herdr workspace create: missing root_pane.pane_id"))?;

        // `pane run` submits the command text plus Enter atomically. It succeeds
        // silently (no JSON), so only check the exit status.
        herdr_ok(&["pane", "run", pane_id, launch]).await?;
        Ok(true)
    }

    async fn focus(&self, _name: &str, path: &Path, attach_if_outside: bool) -> Result<()> {
        self.ensure_server().await?;

        match self.find_by_path(path).await? {
            Some(c) => {
                herdr_ok(&["workspace", "focus", &c.id]).await?;
            }
            None => {
                eprintln!(
                    "Warning: no herdr workspace found for {}",
                    path.display()
                );
            }
        }

        if !self.is_inside() && attach_if_outside {
            // Attach the full UI; it opens on the focused workspace. Blocks until
            // the user detaches, mirroring `tmux attach-session`.
            let status = Command::new("herdr")
                .stdin(Stdio::inherit())
                .stdout(Stdio::inherit())
                .stderr(Stdio::inherit())
                .status()
                .await?;
            if !status.success() {
                return Err(anyhow!("failed to attach herdr UI"));
            }
        }
        Ok(())
    }

    async fn close(&self, container: &Container) -> Result<()> {
        self.ensure_server().await?;
        herdr_ok(&["workspace", "close", &container.id]).await?;
        Ok(())
    }
}

/// Run a `herdr` CLI command that succeeds silently (no JSON body needed);
/// surface a non-zero exit as an error with stderr context.
async fn herdr_ok(args: &[&str]) -> Result<()> {
    let output = Command::new("herdr")
        .args(args)
        .output()
        .await
        .with_context(|| format!("failed to run `herdr {}`", args.join(" ")))?;

    if output.status.success() {
        return Ok(());
    }

    // Some commands report errors as JSON on stdout; prefer that message.
    let stdout = String::from_utf8_lossy(&output.stdout);
    if let Ok(value) = serde_json::from_str::<serde_json::Value>(stdout.trim()) {
        if let Some(message) = value.get("error").and_then(|e| e.get("message")).and_then(|m| m.as_str()) {
            return Err(anyhow!("herdr {} failed: {}", args.join(" "), message));
        }
    }
    let stderr = String::from_utf8_lossy(&output.stderr);
    Err(anyhow!(
        "herdr {} failed{}",
        args.join(" "),
        if stderr.trim().is_empty() {
            String::new()
        } else {
            format!(": {}", stderr.trim())
        }
    ))
}

async fn server_running() -> bool {
    Command::new("herdr")
        .arg("status")
        .arg("server")
        .output()
        .await
        .map(|o| o.status.success())
        .unwrap_or(false)
}

/// Run a `herdr` CLI command that prints a JSON response, returning its
/// `.result` (or the whole document if there is no `result`). Surfaces
/// `.error.message` as an `Err`.
async fn herdr_json(args: &[&str]) -> Result<serde_json::Value> {
    let output = Command::new("herdr")
        .args(args)
        .output()
        .await
        .with_context(|| format!("failed to run `herdr {}`", args.join(" ")))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let trimmed = stdout.trim();
    if trimmed.is_empty() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(anyhow!(
            "herdr {} produced no output{}",
            args.join(" "),
            if stderr.trim().is_empty() {
                String::new()
            } else {
                format!(": {}", stderr.trim())
            }
        ));
    }

    let value: serde_json::Value = serde_json::from_str(trimmed)
        .with_context(|| format!("herdr {}: could not parse JSON:\n{}", args.join(" "), trimmed))?;

    if let Some(err) = value.get("error") {
        let message = err
            .get("message")
            .and_then(|m| m.as_str())
            .unwrap_or("unknown error");
        return Err(anyhow!("herdr {} failed: {}", args.join(" "), message));
    }

    Ok(value.get("result").cloned().unwrap_or(value))
}
