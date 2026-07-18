//! Per-feature cargo target-dir setup: shared vs per-feature target dirs,
//! optional sccache, and reflink-seeded `/scratch` targets on Cloud Workspaces.
//! Ported verbatim from the original single-file `ft`; no behavior change.

use anyhow::Result;
use std::path::{Path, PathBuf};
use tokio::process::Command;

async fn is_rust_project(repo: &Path) -> Result<bool> {
    Ok(repo.join("Cargo.toml").exists())
}

async fn is_cargo_workspace(repo: &Path) -> Result<bool> {
    let cargo_toml = repo.join("Cargo.toml");
    if !cargo_toml.exists() {
        return Ok(false);
    }

    let contents = tokio::fs::read_to_string(&cargo_toml).await?;
    Ok(contents.lines().any(|line| line.trim().starts_with("[workspace]")))
}

async fn has_sccache() -> Result<bool> {
    let output = Command::new("which").arg("sccache").output().await?;
    Ok(output.status.success())
}

/// True on a Snowflake Cloud Workspace: /scratch (a fast, roomy, ephemeral local
/// NVMe) exists as a directory. A Mac dev box has no /scratch.
fn on_cloud_workspace() -> bool {
    Path::new("/scratch").is_dir()
}

/// Per-repo cargo target base on the ephemeral /scratch NVMe, or None off-cloud.
/// Namespaced by the main repo's directory name so same-named features in
/// different repos don't collide.
fn scratch_target_base(main_repo: &Path) -> Option<PathBuf> {
    if !on_cloud_workspace() {
        return None;
    }
    let user = std::env::var("USER").ok().filter(|u| !u.is_empty())?;
    let repo_name = main_repo.file_name()?.to_string_lossy().to_string();
    Some(Path::new("/scratch").join(user).join("ft-targets").join(repo_name))
}

fn dir_has_content(p: &Path) -> bool {
    std::fs::read_dir(p).map(|mut it| it.next().is_some()).unwrap_or(false)
}

/// Pick a warm cache to seed a fresh /scratch target from: prefer a `_primary`
/// cache, else the newest non-empty sibling feature target.
async fn pick_seed_source(base: &Path, feature: &str) -> Option<PathBuf> {
    let primary = base.join("_primary");
    if dir_has_content(&primary) {
        return Some(primary);
    }
    let mut entries = tokio::fs::read_dir(base).await.ok()?;
    let mut best: Option<(std::time::SystemTime, PathBuf)> = None;
    while let Ok(Some(e)) = entries.next_entry().await {
        let p = e.path();
        if e.file_name().to_string_lossy() == feature || !p.is_dir() || !dir_has_content(&p) {
            continue;
        }
        let mtime = e
            .metadata()
            .await
            .ok()
            .and_then(|m| m.modified().ok())
            .unwrap_or(std::time::UNIX_EPOCH);
        if best.as_ref().map(|(t, _)| mtime > *t).unwrap_or(true) {
            best = Some((mtime, p));
        }
    }
    best.map(|(_, p)| p)
}

/// Reflink-seed a fresh /scratch target from a warm sibling (btrfs COW: instant,
/// space-shared) so a new clone starts warm instead of rebuilding from zero.
/// No-op if there's no source, or if FT_CLEAN_TARGET=1.
async fn seed_scratch_target(base: &Path, target_dir: &Path, feature: &str) {
    if std::env::var("FT_CLEAN_TARGET").as_deref() == Ok("1") {
        return;
    }
    let Some(src) = pick_seed_source(base, feature).await else {
        return;
    };
    let src_dot = format!("{}/.", src.display());
    let dst = format!("{}/", target_dir.display());
    let ok = Command::new("cp")
        .args(["--reflink=auto", "-a", &src_dot, &dst])
        .status()
        .await
        .map(|s| s.success())
        .unwrap_or(false);
    if ok {
        println!("Seeded target cache (reflink from {})", src.display());
    }
}

pub async fn setup_cargo_config(worktree_path: &Path, main_repo: &Path, feature: &str) -> Result<()> {
    if !is_rust_project(main_repo).await? {
        return Ok(());
    }

    let scratch_base = scratch_target_base(main_repo);

    // Off-cloud: keep the historical behavior — workspaces use cargo's default
    // shared target dir (in the clone), non-workspaces get a per-feature dir
    // under <main_repo>/.cargo-cache/target. On a Cloud Workspace, put EVERY
    // clone's target on the fast, roomy, ephemeral /scratch NVMe instead (the
    // monorepo workspace has the biggest target, so it benefits most).
    let (target_dir, use_absolute) = if let Some(base) = &scratch_base {
        (base.join(feature), true)
    } else if is_cargo_workspace(main_repo).await? {
        println!("Cargo workspace detected, using default shared target directory");
        return Ok(());
    } else {
        (main_repo.join(".cargo-cache/target").join(feature), false)
    };

    // On /scratch: create the target dir and reflink-seed it from a warm sibling.
    if let Some(base) = &scratch_base {
        tokio::fs::create_dir_all(&target_dir).await?;
        seed_scratch_target(base, &target_dir, feature).await;
    }

    let cargo_dir = worktree_path.join(".cargo");
    tokio::fs::create_dir_all(&cargo_dir).await?;

    let target_str = if use_absolute {
        target_dir.display().to_string()
    } else {
        pathdiff::diff_paths(&target_dir, worktree_path)
            .unwrap_or_else(|| target_dir.clone())
            .display()
            .to_string()
    };

    // One [build] table (target-dir + optional sccache wrapper); two separate
    // [build] tables would be a TOML redefinition error.
    let mut config_content = String::from("[build]\n");
    config_content.push_str(&format!("target-dir = \"{}\"\n", target_str));
    if has_sccache().await? {
        config_content.push_str("rustc-wrapper = \"sccache\"\n");
        println!("Enabling sccache for compilation caching");
    }

    let config_path = cargo_dir.join("config.toml");
    tokio::fs::write(&config_path, config_content).await?;

    println!("Created .cargo/config.toml with target-dir: {}", target_str);

    Ok(())
}
