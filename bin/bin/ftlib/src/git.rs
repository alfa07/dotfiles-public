//! Git and `gh` helpers: repo discovery, feature-clone/worktree enumeration,
//! clone creation, status/landed/PR/CI inspection, and branch cleanup.
//! Ported verbatim from the original single-file `ft`; no behavior change.

use anyhow::{anyhow, Context, Result};
use std::collections::HashSet;
use std::io;
use std::path::{Path, PathBuf};
use tokio::process::Command;

use crate::feature::{
    BranchInfo, CiStatus, Feature, FeatureKind, FeatureStatus, PrInfo, StaleReason,
};

pub async fn run_command(cwd: &Path, cmd: &str, args: &[&str]) -> Result<()> {
    let status = Command::new(cmd)
        .current_dir(cwd)
        .args(args)
        .status()
        .await?;

    if !status.success() {
        return Err(anyhow!("Command failed: {} {}", cmd, args.join(" ")));
    }

    Ok(())
}

pub async fn find_main_repo() -> Result<PathBuf> {
    let cfg = Command::new("git")
        .arg("config")
        .arg("--local")
        .arg("--get")
        .arg("ft.mainRepo")
        .output()
        .await;
    if let Ok(out) = cfg {
        if out.status.success() {
            let path = String::from_utf8(out.stdout)?.trim().to_string();
            if !path.is_empty() {
                let pb = PathBuf::from(&path);
                if pb.exists() {
                    return Ok(std::fs::canonicalize(pb)?);
                }
                eprintln!("Warning: ft.mainRepo config points to missing path: {}", path);
            }
        }
    }

    let output = Command::new("git")
        .arg("rev-parse")
        .arg("--git-common-dir")
        .output()
        .await
        .context("Failed to run git rev-parse")?;

    if !output.status.success() {
        return Err(anyhow!("Not in a git repository"));
    }

    let git_common_dir = String::from_utf8(output.stdout)?.trim().to_string();
    let git_common_path = PathBuf::from(&git_common_dir);

    let output = Command::new("git")
        .arg("rev-parse")
        .arg("--git-dir")
        .output()
        .await?;

    let git_dir = String::from_utf8(output.stdout)?.trim().to_string();
    let gitdir_file = PathBuf::from(&git_dir).join("gitdir");

    let main_repo = if gitdir_file.exists() {
        git_common_path
            .parent()
            .ok_or_else(|| anyhow!("Failed to get parent of git common dir"))?
            .to_path_buf()
    } else {
        let output = Command::new("git")
            .arg("rev-parse")
            .arg("--show-toplevel")
            .output()
            .await?;

        if !output.status.success() {
            return Err(anyhow!("Failed to find git toplevel"));
        }

        PathBuf::from(String::from_utf8(output.stdout)?.trim())
    };

    Ok(std::fs::canonicalize(main_repo)?)
}

pub async fn list_features(main_repo: &Path) -> Result<Vec<Feature>> {
    let mut features = Vec::new();

    let wt_dir = main_repo.join(".wt");
    let entries = match std::fs::read_dir(&wt_dir) {
        Ok(e) => e,
        Err(ref err) if err.kind() == io::ErrorKind::NotFound => return Ok(features),
        Err(err) => return Err(err).context("Failed to read .wt directory"),
    };

    let porcelain_worktrees = list_porcelain_worktrees(main_repo).await.unwrap_or_default();

    for entry in entries {
        let entry = entry?;
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }
        let git_path = path.join(".git");
        if !git_path.exists() {
            continue;
        }

        let kind = if git_path.is_dir() {
            FeatureKind::Clone
        } else {
            FeatureKind::Worktree
        };

        let canon = std::fs::canonicalize(&path).unwrap_or_else(|_| path.clone());

        let (branch, commit) = match kind {
            FeatureKind::Clone => read_clone_head(&path)
                .await
                .unwrap_or_else(|_| ("HEAD".to_string(), String::new())),
            FeatureKind::Worktree => porcelain_worktrees
                .iter()
                .find(|(wt_path, _, _)| {
                    std::fs::canonicalize(wt_path).ok().as_deref() == Some(&canon)
                })
                .map(|(_, branch, commit)| (branch.clone(), commit.clone()))
                .unwrap_or_else(|| ("HEAD".to_string(), String::new())),
        };

        features.push(Feature {
            path,
            kind,
            branch,
            commit,
            is_current: false,
        });
    }

    if let Ok(current_path) = std::env::current_dir() {
        let current_canon = std::fs::canonicalize(current_path).ok();
        for f in &mut features {
            if let Ok(f_canon) = std::fs::canonicalize(&f.path) {
                if Some(&f_canon) == current_canon.as_ref() {
                    f.is_current = true;
                    break;
                }
            }
        }
    }

    features.sort_by(|a, b| a.path.cmp(&b.path));
    Ok(features)
}

async fn list_porcelain_worktrees(repo: &Path) -> Result<Vec<(PathBuf, String, String)>> {
    let output = Command::new("git")
        .current_dir(repo)
        .arg("worktree")
        .arg("list")
        .arg("--porcelain")
        .output()
        .await?;

    if !output.status.success() {
        return Err(anyhow!("Failed to list worktrees"));
    }

    let stdout = String::from_utf8(output.stdout)?;
    let mut out = Vec::new();
    let mut current_path: Option<PathBuf> = None;
    let mut current_commit: Option<String> = None;
    let mut current_branch: Option<String> = None;

    let flush = |path: &mut Option<PathBuf>,
                 commit: &mut Option<String>,
                 branch: &mut Option<String>,
                 out: &mut Vec<(PathBuf, String, String)>| {
        if let (Some(p), Some(c)) = (path.take(), commit.take()) {
            out.push((p, branch.take().unwrap_or_else(|| "HEAD".to_string()), c));
        } else {
            branch.take();
        }
    };

    for line in stdout.lines() {
        if let Some(path) = line.strip_prefix("worktree ") {
            current_path = Some(PathBuf::from(path));
        } else if let Some(commit) = line.strip_prefix("HEAD ") {
            current_commit = Some(commit.to_string());
        } else if let Some(branch) = line.strip_prefix("branch ") {
            current_branch = Some(branch.to_string());
        } else if line.is_empty() {
            flush(&mut current_path, &mut current_commit, &mut current_branch, &mut out);
        }
    }
    flush(&mut current_path, &mut current_commit, &mut current_branch, &mut out);

    Ok(out)
}

async fn read_clone_head(path: &Path) -> Result<(String, String)> {
    let branch_out = Command::new("git")
        .current_dir(path)
        .arg("rev-parse")
        .arg("--abbrev-ref")
        .arg("HEAD")
        .output()
        .await?;
    let branch_name = String::from_utf8(branch_out.stdout)?.trim().to_string();
    let branch_ref = if branch_name.is_empty() || branch_name == "HEAD" {
        "HEAD".to_string()
    } else {
        format!("refs/heads/{}", branch_name)
    };

    let commit_out = Command::new("git")
        .current_dir(path)
        .arg("rev-parse")
        .arg("HEAD")
        .output()
        .await?;
    let commit = String::from_utf8(commit_out.stdout)?.trim().to_string();

    Ok((branch_ref, commit))
}

pub async fn get_main_branch(repo: &Path) -> Result<String> {
    for branch in &["main", "master"] {
        let output = Command::new("git")
            .current_dir(repo)
            .arg("show-ref")
            .arg("--verify")
            .arg("--quiet")
            .arg(format!("refs/heads/{}", branch))
            .output()
            .await?;

        if output.status.success() {
            return Ok(branch.to_string());
        }
    }

    Err(anyhow!("Could not find main or master branch"))
}

pub async fn fetch_origin(repo: &Path) -> Result<()> {
    let has_remote = Command::new("git")
        .current_dir(repo)
        .arg("remote")
        .output()
        .await?
        .stdout
        .contains(&b"origin"[0]);

    if !has_remote {
        return Ok(());
    }

    println!("Fetching latest changes from origin...");

    let main_result = Command::new("git")
        .current_dir(repo)
        .arg("fetch")
        .arg("origin")
        .arg("main")
        .output()
        .await;

    if main_result.is_ok() && main_result.unwrap().status.success() {
        return Ok(());
    }

    let master_result = Command::new("git")
        .current_dir(repo)
        .arg("fetch")
        .arg("origin")
        .arg("master")
        .output()
        .await;

    if master_result.is_ok() && master_result.unwrap().status.success() {
        return Ok(());
    }

    Ok(())
}

async fn git_effective_config(repo: &Path, key: &str) -> Result<Option<String>> {
    let output = Command::new("git")
        .current_dir(repo)
        .arg("config")
        .arg("--get")
        .arg(key)
        .output()
        .await?;
    if !output.status.success() {
        return Ok(None);
    }
    let value = String::from_utf8(output.stdout)?.trim().to_string();
    if value.is_empty() {
        return Ok(None);
    }
    Ok(Some(value))
}

async fn git_remote_url(repo: &Path, remote: &str) -> Result<String> {
    let output = Command::new("git")
        .current_dir(repo)
        .arg("remote")
        .arg("get-url")
        .arg(remote)
        .output()
        .await?;
    if !output.status.success() {
        return Err(anyhow!("git remote get-url {} failed", remote));
    }
    let url = String::from_utf8(output.stdout)?.trim().to_string();
    if url.is_empty() {
        return Err(anyhow!("git remote get-url {} returned empty", remote));
    }
    Ok(url)
}

async fn remote_branch_exists(repo: &Path, branch: &str) -> Result<bool> {
    let output = Command::new("git")
        .current_dir(repo)
        .arg("show-ref")
        .arg("--verify")
        .arg("--quiet")
        .arg(format!("refs/remotes/origin/{}", branch))
        .output()
        .await?;
    Ok(output.status.success())
}

pub async fn create_feature_clone(
    main_repo: &Path,
    feature_path: &Path,
    feature: &str,
    main_branch: &str,
) -> Result<()> {
    let origin_url = git_remote_url(main_repo, "origin").await.with_context(|| {
        "Main repository has no `origin` remote — `ft` clone mode requires an origin URL"
    })?;

    println!("Cloning {} into {}", origin_url, feature_path.display());

    let use_reference = std::env::var("FT_NO_REFERENCE").ok().as_deref() != Some("1");

    let main_repo_str = main_repo.to_string_lossy().to_string();
    let feature_path_str = feature_path.to_string_lossy().to_string();

    let mut clone_args: Vec<&str> = vec!["clone", "--filter=blob:none", "--no-checkout"];
    if use_reference {
        clone_args.push("--reference-if-able");
        clone_args.push(&main_repo_str);
    }
    clone_args.push(&origin_url);
    clone_args.push(&feature_path_str);

    run_command(main_repo, "git", &clone_args).await?;

    let main_repo_canon =
        std::fs::canonicalize(main_repo).unwrap_or_else(|_| main_repo.to_path_buf());
    run_command(
        feature_path,
        "git",
        &[
            "config",
            "--local",
            "ft.mainRepo",
            main_repo_canon.to_str().unwrap(),
        ],
    )
    .await?;

    for key in ["user.name", "user.email"] {
        if let Some(value) = git_effective_config(main_repo, key).await? {
            run_command(feature_path, "git", &["config", "--local", key, value.as_str()]).await?;
        }
    }

    let _ = Command::new("git")
        .current_dir(feature_path)
        .arg("fetch")
        .arg("origin")
        .arg(main_branch)
        .status()
        .await;

    if remote_branch_exists(feature_path, feature).await? {
        println!("Checking out existing remote branch: {}", feature);
        run_command(feature_path, "git", &["checkout", feature]).await?;
    } else {
        let start_point = format!("origin/{}", main_branch);
        println!("Creating new branch {} from {}", feature, start_point);
        run_command(
            feature_path,
            "git",
            &["checkout", "--no-track", "-b", feature, &start_point],
        )
        .await?;
    }

    Ok(())
}

/// Gerrit shard for a change number: the last two digits, zero-padded
/// (`refs/changes/<shard>/<change>/<patchset>`). Change 94000 -> "00", 5 -> "05".
fn gerrit_shard(change: u64) -> String {
    format!("{:02}", change % 100)
}

/// Remote to fetch Gerrit changes from: `ft.gerritRemote` if set, else `origin`.
async fn gerrit_remote(repo: &Path) -> Result<String> {
    if let Some(remote) = git_effective_config(repo, "ft.gerritRemote").await? {
        return Ok(remote);
    }
    Ok("origin".to_string())
}

/// Highest patchset number published for a Gerrit change, discovered via
/// `git ls-remote`. The `meta` ref and any non-numeric patchset are ignored.
async fn latest_gerrit_patchset(repo: &Path, remote: &str, change: u64) -> Result<u32> {
    let shard = gerrit_shard(change);
    let pattern = format!("refs/changes/{}/{}/*", shard, change);
    let output = Command::new("git")
        .current_dir(repo)
        .arg("ls-remote")
        .arg(remote)
        .arg(&pattern)
        .output()
        .await
        .context("Failed to spawn git ls-remote")?;

    if !output.status.success() {
        return Err(anyhow!(
            "git ls-remote {} {} failed: {}",
            remote,
            pattern,
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }

    let stdout = String::from_utf8(output.stdout)?;
    let mut max_patchset = 0u32;
    for line in stdout.lines() {
        let refname = match line.split_once('\t') {
            Some((_, r)) => r,
            None => continue,
        };
        if let Some(patchset) = refname.rsplit('/').next() {
            if let Ok(n) = patchset.parse::<u32>() {
                max_patchset = max_patchset.max(n);
            }
        }
    }

    if max_patchset == 0 {
        return Err(anyhow!(
            "No patchsets found for change {} on remote {} (is the change number correct?)",
            change,
            remote
        ));
    }

    Ok(max_patchset)
}

async fn local_branch_exists(repo: &Path, branch: &str) -> Result<bool> {
    let output = Command::new("git")
        .current_dir(repo)
        .arg("show-ref")
        .arg("--verify")
        .arg("--quiet")
        .arg(format!("refs/heads/{}", branch))
        .output()
        .await?;
    Ok(output.status.success())
}

/// Create a worktree under `.wt/` checked out to the latest patchset of a Gerrit
/// change. Fetches `refs/changes/<shard>/<change>/<patchset>` into the main repo,
/// then adds a worktree on a fresh local branch pointing at it. If the branch
/// already exists locally it is reused as-is (the fetched patchset is ignored).
pub async fn create_gerrit_worktree(
    main_repo: &Path,
    feature_path: &Path,
    branch: &str,
    change: u64,
) -> Result<()> {
    let remote = gerrit_remote(main_repo).await?;
    let patchset = latest_gerrit_patchset(main_repo, &remote, change).await?;
    let shard = gerrit_shard(change);
    let change_ref = format!("refs/changes/{}/{}/{}", shard, change, patchset);

    println!(
        "Fetching Gerrit change {} (patchset {}) from {}",
        change, patchset, remote
    );
    run_command(main_repo, "git", &["fetch", &remote, &change_ref]).await?;

    let feature_path_str = feature_path.to_string_lossy().to_string();

    if local_branch_exists(main_repo, branch).await? {
        println!(
            "Local branch {} already exists; adding worktree on it (fetched patchset ignored)",
            branch
        );
        run_command(
            main_repo,
            "git",
            &["worktree", "add", &feature_path_str, branch],
        )
        .await?;
    } else {
        println!(
            "Creating worktree {} on branch {} at {}",
            feature_path.display(),
            branch,
            change_ref
        );
        run_command(
            main_repo,
            "git",
            &[
                "worktree",
                "add",
                "-b",
                branch,
                &feature_path_str,
                "FETCH_HEAD",
            ],
        )
        .await?;
    }

    Ok(())
}

pub async fn get_feature_status(feature: &Feature, main_repo: &Path) -> Result<FeatureStatus> {
    let uncommitted_output = Command::new("git")
        .current_dir(&feature.path)
        .arg("status")
        .arg("--porcelain")
        .output()
        .await?;

    let uncommitted_count = if uncommitted_output.status.success() {
        String::from_utf8(uncommitted_output.stdout)?.lines().count()
    } else {
        0
    };

    let main_branch = get_main_branch(main_repo).await?;

    let diff_output = Command::new("git")
        .current_dir(&feature.path)
        .arg("diff")
        .arg(format!("origin/{}...HEAD", main_branch))
        .arg("--shortstat")
        .output()
        .await?;

    let (files_changed, insertions, deletions) = if diff_output.status.success() {
        parse_diff_shortstat(&String::from_utf8(diff_output.stdout)?)
    } else {
        (0, 0, 0)
    };

    let landed_repo = match feature.kind {
        FeatureKind::Worktree => main_repo.to_path_buf(),
        FeatureKind::Clone => feature.path.clone(),
    };
    let is_landed = is_landed(&feature.branch, &feature.commit, &landed_repo).await?;

    let pr_info = get_pr_info(&feature.branch).await.ok();

    Ok(FeatureStatus {
        uncommitted_count,
        _files_changed: files_changed,
        insertions,
        deletions,
        is_landed,
        pr_info,
    })
}

fn parse_diff_shortstat(output: &str) -> (usize, usize, usize) {
    let mut files = 0;
    let mut insertions = 0;
    let mut deletions = 0;

    for part in output.split(',') {
        let part = part.trim();
        if let Some(num_str) = part.split_whitespace().next() {
            if let Ok(num) = num_str.parse::<usize>() {
                if part.contains("file") {
                    files = num;
                } else if part.contains("insertion") {
                    insertions = num;
                } else if part.contains("deletion") {
                    deletions = num;
                }
            }
        }
    }

    (files, insertions, deletions)
}

async fn is_landed(branch: &str, commit: &str, repo: &Path) -> Result<bool> {
    let main_branch = get_main_branch(repo).await?;

    let merge_base_output = Command::new("git")
        .current_dir(repo)
        .arg("merge-base")
        .arg("--is-ancestor")
        .arg(commit)
        .arg(format!("origin/{}", main_branch))
        .output()
        .await?;

    if merge_base_output.status.success() {
        return Ok(true);
    }

    let branch_name = branch.strip_prefix("refs/heads/").unwrap_or(branch);
    if get_pr_info(branch_name).await.is_ok() {
        return Ok(true);
    }

    Ok(false)
}

async fn get_pr_info(branch: &str) -> Result<PrInfo> {
    let branch_name = branch.strip_prefix("refs/heads/").unwrap_or(branch);

    let output = Command::new("gh")
        .arg("pr")
        .arg("list")
        .arg("--state")
        .arg("merged")
        .arg("--head")
        .arg(branch_name)
        .arg("--json")
        .arg("number,url")
        .output()
        .await?;

    if !output.status.success() {
        return Err(anyhow!("gh CLI failed"));
    }

    let stdout = String::from_utf8(output.stdout)?;
    let prs: Vec<serde_json::Value> = serde_json::from_str(&stdout)?;

    if let Some(pr) = prs.first() {
        let number = pr["number"].as_u64().unwrap_or(0) as u32;
        let url = pr["url"].as_str().unwrap_or("").to_string();
        let ci_status = get_ci_status(number).await.unwrap_or(CiStatus::None);
        return Ok(PrInfo { number, url, ci_status });
    }

    let output = Command::new("gh")
        .arg("pr")
        .arg("list")
        .arg("--head")
        .arg(branch_name)
        .arg("--json")
        .arg("number,url")
        .output()
        .await?;

    if !output.status.success() {
        return Err(anyhow!("gh CLI failed"));
    }

    let stdout = String::from_utf8(output.stdout)?;
    let prs: Vec<serde_json::Value> = serde_json::from_str(&stdout)?;

    if let Some(pr) = prs.first() {
        let number = pr["number"].as_u64().unwrap_or(0) as u32;
        let url = pr["url"].as_str().unwrap_or("").to_string();
        let ci_status = get_ci_status(number).await.unwrap_or(CiStatus::None);
        return Ok(PrInfo { number, url, ci_status });
    }

    Err(anyhow!("No PR found"))
}

async fn get_ci_status(pr_number: u32) -> Result<CiStatus> {
    let output = Command::new("gh")
        .arg("pr")
        .arg("view")
        .arg(pr_number.to_string())
        .arg("--json")
        .arg("statusCheckRollup")
        .output()
        .await?;

    if !output.status.success() {
        return Ok(CiStatus::None);
    }

    let stdout = String::from_utf8(output.stdout)?;
    let data: serde_json::Value = serde_json::from_str(&stdout)?;

    if let Some(checks) = data["statusCheckRollup"].as_array() {
        if checks.is_empty() {
            return Ok(CiStatus::None);
        }

        let mut has_pending = false;
        let mut has_failure = false;

        for check in checks {
            if let Some(conclusion) = check["conclusion"].as_str() {
                match conclusion {
                    "FAILURE" | "TIMED_OUT" | "CANCELLED" => has_failure = true,
                    "PENDING" | "IN_PROGRESS" => has_pending = true,
                    _ => {}
                }
            } else if let Some(state) = check["state"].as_str() {
                match state {
                    "PENDING" | "IN_PROGRESS" => has_pending = true,
                    "FAILURE" | "ERROR" => has_failure = true,
                    _ => {}
                }
            }
        }

        if has_failure {
            return Ok(CiStatus::Failure);
        }
        if has_pending {
            return Ok(CiStatus::Pending);
        }

        return Ok(CiStatus::Success);
    }

    Ok(CiStatus::None)
}

pub async fn remove_feature(main_repo: &Path, feature: &Feature) -> Result<()> {
    match feature.kind {
        FeatureKind::Worktree => {
            let status = Command::new("git")
                .current_dir(main_repo)
                .arg("worktree")
                .arg("remove")
                .arg(&feature.path)
                .arg("--force")
                .status()
                .await?;

            if !status.success() {
                return Err(anyhow!("Failed to remove worktree"));
            }
            Ok(())
        }
        FeatureKind::Clone => {
            tokio::fs::remove_dir_all(&feature.path)
                .await
                .with_context(|| format!("Failed to remove clone at {}", feature.path.display()))?;
            Ok(())
        }
    }
}

pub async fn ensure_gitignore_entries(repo: &Path) -> Result<()> {
    let gitignore_path = repo.join(".gitignore");
    let entries = vec![".wt/", ".cargo-cache/"];

    let existing_content = if gitignore_path.exists() {
        tokio::fs::read_to_string(&gitignore_path).await?
    } else {
        String::new()
    };

    let mut new_entries = Vec::new();
    for entry in &entries {
        if !existing_content.lines().any(|line| line.trim() == *entry) {
            new_entries.push(entry);
        }
    }

    if !new_entries.is_empty() {
        let mut content = existing_content;
        if !content.is_empty() && !content.ends_with('\n') {
            content.push('\n');
        }

        if !content.contains("# Git worktrees") {
            content.push_str("\n# Git worktrees (created by ft script)\n");
        }

        for entry in new_entries {
            content.push_str(entry);
            content.push('\n');
        }

        tokio::fs::write(&gitignore_path, content).await?;
    }

    Ok(())
}

pub async fn list_branch_infos(repo: &Path) -> Result<Vec<BranchInfo>> {
    let format = "%(refname:short)%00%(upstream:track)%00%(worktreepath)%00%(subject)";
    let output = Command::new("git")
        .current_dir(repo)
        .arg("for-each-ref")
        .arg(format!("--format={}", format))
        .arg("refs/heads/")
        .output()
        .await
        .context("Failed to spawn git for-each-ref")?;
    if !output.status.success() {
        return Err(anyhow!(
            "git for-each-ref failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }
    let stdout = String::from_utf8(output.stdout)?;
    let mut out = Vec::new();
    for line in stdout.lines() {
        if line.is_empty() {
            continue;
        }
        let parts: Vec<&str> = line.splitn(4, '\0').collect();
        if parts.len() < 4 {
            continue;
        }
        out.push(BranchInfo {
            name: parts[0].to_string(),
            track: parts[1].to_string(),
            worktree_path: parts[2].to_string(),
            subject: parts[3].to_string(),
        });
    }
    Ok(out)
}

pub async fn list_merged_into_origin_main(
    repo: &Path,
    main_branch: &str,
) -> Result<HashSet<String>> {
    let origin_main = format!("origin/{}", main_branch);
    let exists = Command::new("git")
        .current_dir(repo)
        .arg("rev-parse")
        .arg("--verify")
        .arg("--quiet")
        .arg(&origin_main)
        .output()
        .await?;
    if !exists.status.success() {
        return Ok(HashSet::new());
    }

    let output = Command::new("git")
        .current_dir(repo)
        .arg("for-each-ref")
        .arg("--format=%(refname:short)")
        .arg(format!("--merged={}", origin_main))
        .arg("refs/heads/")
        .output()
        .await
        .context("Failed to spawn git for-each-ref --merged")?;
    if !output.status.success() {
        return Err(anyhow!(
            "git for-each-ref --merged failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }
    let stdout = String::from_utf8(output.stdout)?;
    Ok(stdout
        .lines()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect())
}

/// Classify local branches as stale (merged into origin/main and/or upstream gone).
pub fn classify_stale_branches(
    branches: Vec<BranchInfo>,
    merged_set: &HashSet<String>,
    main_branch: &str,
) -> Vec<(BranchInfo, StaleReason)> {
    let mut candidates = Vec::new();
    for b in branches {
        if !b.worktree_path.is_empty() {
            continue;
        }
        if b.name == main_branch {
            continue;
        }
        let is_gone = b.track.contains("gone");
        let is_merged = merged_set.contains(&b.name);
        let reason = match (is_gone, is_merged) {
            (true, true) => StaleReason::GoneAndMerged,
            (true, false) => StaleReason::Gone,
            (false, true) => StaleReason::Merged,
            (false, false) => continue,
        };
        candidates.push((b, reason));
    }
    candidates
}
