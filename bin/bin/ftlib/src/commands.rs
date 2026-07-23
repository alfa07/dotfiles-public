//! Subcommand implementations. Git/clone/cleanup logic is unchanged from the
//! original `ft`; the tmux-specific calls are replaced by the `Multiplexer`
//! abstraction so the same flows work on herdr and tmux.

use anyhow::{anyhow, Context, Result};
use std::io;
use tokio::process::Command;

use crate::cargo_setup::setup_cargo_config;
use crate::git::{
    classify_stale_branches, create_feature_clone, create_gerrit_worktree, ensure_gitignore_entries,
    fetch_origin, find_main_repo, get_feature_status, get_main_branch, list_branch_infos,
    list_features, list_merged_into_origin_main, remove_feature,
};
use crate::mux::Multiplexer;
use crate::tui::{run_cleanup_tui, run_fuzzy_finder, CleanupItem};

const LAUNCH_NEW: &str = "claude --dangerously-skip-permissions";
const LAUNCH_RESUME: &str = "claude --dangerously-skip-permissions --resume";

pub async fn cmd_new(mux: &Multiplexer, feature: &str) -> Result<()> {
    let main_repo = find_main_repo().await?;
    println!("Main repository: {}", main_repo.display());

    if let Err(e) = fetch_origin(&main_repo).await {
        eprintln!("Warning: Failed to fetch from origin: {}", e);
    }

    let main_branch = get_main_branch(&main_repo).await?;
    println!("Main branch: {}", main_branch);

    let feature_path = main_repo.join(".wt").join(feature);

    let existing_features = list_features(&main_repo).await?;
    let feature_exists = existing_features.iter().any(|f| f.path == feature_path);

    if feature_exists {
        println!("Feature already exists at {}", feature_path.display());
    } else {
        std::fs::create_dir_all(main_repo.join(".wt")).context("Failed to create .wt directory")?;
        create_feature_clone(&main_repo, &feature_path, feature, &main_branch).await?;
    }

    ensure_gitignore_entries(&main_repo).await?;
    setup_cargo_config(&feature_path, &main_repo, feature).await?;

    let created = mux.ensure(feature, &feature_path, LAUNCH_NEW).await?;
    if !created {
        println!("Reusing existing {} container for {}", mux.kind_label(), feature);
    }
    mux.focus(feature, &feature_path, true).await?;

    Ok(())
}

pub async fn cmd_gr(mux: &Multiplexer, change: u64) -> Result<()> {
    let main_repo = find_main_repo().await?;
    println!("Main repository: {}", main_repo.display());

    let feature = format!("gerrit-{}", change);
    let feature_path = main_repo.join(".wt").join(&feature);

    let existing_features = list_features(&main_repo).await?;
    let feature_exists = existing_features.iter().any(|f| f.path == feature_path);

    if feature_exists {
        println!("Feature already exists at {}", feature_path.display());
    } else {
        std::fs::create_dir_all(main_repo.join(".wt")).context("Failed to create .wt directory")?;
        create_gerrit_worktree(&main_repo, &feature_path, &feature, change).await?;
    }

    ensure_gitignore_entries(&main_repo).await?;
    setup_cargo_config(&feature_path, &main_repo, &feature).await?;

    let created = mux.ensure(&feature, &feature_path, LAUNCH_NEW).await?;
    if !created {
        println!("Reusing existing {} container for {}", mux.kind_label(), feature);
    }
    mux.focus(&feature, &feature_path, true).await?;

    Ok(())
}

pub async fn cmd_go(mux: &Multiplexer, feature: &Option<String>) -> Result<()> {
    let main_repo = find_main_repo().await?;
    let features = list_features(&main_repo).await?;

    let target = if feature.is_none() {
        if features.is_empty() {
            return Err(anyhow!("No features to switch to"));
        }

        let items: Vec<String> = features
            .iter()
            .map(|f| {
                let marker = if f.is_current { " (current)" } else { "" };
                format!("{}{}", f.branch_name(), marker)
            })
            .collect();

        let selected = run_fuzzy_finder(&items)?;
        if selected.is_none() {
            return Err(anyhow!("No feature selected"));
        }

        let selected_branch = selected.unwrap().trim_end_matches(" (current)").to_string();

        features
            .iter()
            .find(|f| f.branch_name() == selected_branch)
            .ok_or_else(|| anyhow!("Feature not found"))?
    } else {
        let feature_name = feature.as_ref().unwrap();
        let matching: Vec<_> = features
            .iter()
            .filter(|f| {
                let branch_name = f.branch_name();
                branch_name == feature_name || branch_name.contains(feature_name)
            })
            .collect();

        match matching.len() {
            0 => return Err(anyhow!("No feature found for: {}", feature_name)),
            1 => matching[0],
            _ => {
                println!("Multiple matches found:");
                for (i, f) in matching.iter().enumerate() {
                    println!("  {}: {} ({})", i + 1, f.branch_name(), f.path.display());
                }
                print!("Select (1-{}): ", matching.len());
                io::Write::flush(&mut io::stdout())?;

                let mut input = String::new();
                io::stdin().read_line(&mut input)?;
                let choice: usize = input.trim().parse().context("Invalid selection")?;

                matching
                    .get(choice - 1)
                    .ok_or_else(|| anyhow!("Selection out of range"))?
            }
        }
    };

    let branch_name = target.branch_name().to_string();
    setup_cargo_config(&target.path, &main_repo, &branch_name).await?;
    mux.ensure(&branch_name, &target.path, LAUNCH_NEW).await?;
    mux.focus(&branch_name, &target.path, true).await?;

    Ok(())
}

pub async fn cmd_restore(mux: &Multiplexer) -> Result<()> {
    let main_repo = find_main_repo().await?;
    let features = list_features(&main_repo).await?;

    let mut restored = 0usize;
    let mut skipped = 0usize;
    let mut failed = 0usize;
    let mut total = 0usize;

    for f in &features {
        let f_canon = match std::fs::canonicalize(&f.path) {
            Ok(p) => p,
            Err(e) => {
                eprintln!("skip  {}: cannot canonicalize ({})", f.path.display(), e);
                continue;
            }
        };

        if f.branch == "HEAD" {
            eprintln!("skip  {}: detached HEAD", f.path.display());
            continue;
        }

        total += 1;
        let branch = f.branch_name();

        match mux.ensure(branch, &f_canon, LAUNCH_RESUME).await {
            Ok(true) => {
                println!("restore {}", branch);
                restored += 1;
            }
            Ok(false) => {
                println!("skip  {} (container exists)", branch);
                skipped += 1;
            }
            Err(e) => {
                eprintln!("fail  {}: {}", branch, e);
                failed += 1;
            }
        }
    }

    println!(
        "\nRestored {}, skipped {}, failed {} of {} features",
        restored, skipped, failed, total
    );
    Ok(())
}

pub async fn cmd_clean(mux: &Multiplexer) -> Result<()> {
    let main_repo = find_main_repo().await?;
    let features = list_features(&main_repo).await?;

    if features.is_empty() {
        println!("No features to clean");
        return Ok(());
    }

    let non_current: Vec<_> = features.iter().filter(|f| !f.is_current).cloned().collect();

    if non_current.is_empty() {
        println!("No features to clean (all features are currently in use)");
        return Ok(());
    }

    let mut items = Vec::new();

    let all_containers = mux.list().await.unwrap_or_default();

    let total = non_current.len();
    let pb = indicatif::ProgressBar::new_spinner();
    pb.enable_steady_tick(std::time::Duration::from_millis(100));

    for (idx, feature) in non_current.into_iter().enumerate() {
        let branch = feature.branch_name().to_string();
        pb.set_message(format!("[{}/{}] Analyzing {}", idx + 1, total, branch));

        let status = get_feature_status(&feature, &main_repo).await?;
        let containers = mux.find_for_feature(&feature).await?;

        let name_match = feature
            .path
            .file_name()
            .and_then(|n| n.to_str())
            .map(|name| all_containers.iter().any(|c| c.name == name))
            .unwrap_or(false);

        let has_open = !containers.is_empty() || name_match;

        let selected = status.is_landed && status.uncommitted_count == 0 && !has_open;

        items.push(CleanupItem {
            feature,
            status,
            selected,
            containers,
            has_open,
        });
    }

    pb.finish_and_clear();

    items.sort_by_key(|i| i.selected);

    let selected_items = run_cleanup_tui(items)?;

    if selected_items.is_empty() {
        println!("No features selected for deletion");
        return Ok(());
    }

    println!("\nDelete {} feature(s)?", selected_items.len());
    println!("\nFeatures:");
    for item in &selected_items {
        println!(
            "  - {} [{}]",
            item.feature.branch_name(),
            item.feature.kind.label()
        );
    }

    let total_containers: usize = selected_items.iter().map(|i| i.containers.len()).sum();
    if total_containers > 0 {
        println!("\nContainers ({}):", total_containers);
        for item in &selected_items {
            for c in &item.containers {
                println!("  - {} \"{}\"", c.display, c.name);
            }
        }
    }

    print!("\nContinue? (y/N): ");
    io::Write::flush(&mut io::stdout())?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;

    if !input.trim().eq_ignore_ascii_case("y") {
        println!("Cancelled");
        return Ok(());
    }

    let mut deleted_features = 0;
    let mut deleted_containers = 0;

    for item in selected_items {
        let branch_name = item.feature.branch_name();

        for c in &item.containers {
            if let Err(e) = mux.close(c).await {
                eprintln!("Warning: Failed to close container {}: {}", c.id, e);
            } else {
                deleted_containers += 1;
            }
        }

        print!("Removing {} [{}]... ", branch_name, item.feature.kind.label());
        io::Write::flush(&mut io::stdout())?;

        match remove_feature(&main_repo, &item.feature).await {
            Ok(_) => {
                println!("✓");
                deleted_features += 1;
            }
            Err(e) => {
                println!("✗ ({})", e);
            }
        }
    }

    println!(
        "\nDeleted {} feature(s), closed {} container(s)",
        deleted_features, deleted_containers
    );

    if let Err(e) = cmd_clean_stale_branches(false, false).await {
        eprintln!("Warning: stale-branch cleanup failed: {}", e);
    }

    Ok(())
}

pub async fn cmd_clean_stale_branches(no_fetch: bool, yes: bool) -> Result<()> {
    let main_repo = find_main_repo().await?;
    let main_branch = get_main_branch(&main_repo).await?;

    if !no_fetch {
        println!("Fetching origin with --prune...");
        let status = Command::new("git")
            .current_dir(&main_repo)
            .arg("fetch")
            .arg("--all")
            .arg("--prune")
            .status()
            .await
            .context("Failed to spawn git fetch")?;
        if !status.success() {
            eprintln!("Warning: git fetch --all --prune failed; classification may be stale");
        }
    }

    let branches = list_branch_infos(&main_repo).await?;
    let merged_set = list_merged_into_origin_main(&main_repo, &main_branch).await?;
    let candidates = classify_stale_branches(branches, &merged_set, &main_branch);

    if candidates.is_empty() {
        println!("No stale branches in {}", main_repo.display());
        return Ok(());
    }

    let max_tag = candidates
        .iter()
        .map(|(_, r)| r.label().len() + 2)
        .max()
        .unwrap_or(0);
    let max_name = candidates.iter().map(|(b, _)| b.name.len()).max().unwrap_or(0);

    println!("\nStale branches in {}:\n", main_repo.display());
    for (b, r) in &candidates {
        let tag = format!("[{}]", r.label());
        println!(
            "  {:<tw$}  {:<nw$}  {}",
            tag,
            b.name,
            b.subject,
            tw = max_tag,
            nw = max_name
        );
    }
    println!();

    if !yes {
        print!("Delete {} branch(es)? (y/N): ", candidates.len());
        io::Write::flush(&mut io::stdout())?;
        let mut input = String::new();
        io::stdin().read_line(&mut input)?;
        if !input.trim().eq_ignore_ascii_case("y") {
            println!("Cancelled");
            return Ok(());
        }
    }

    let mut deleted = 0usize;
    let mut failed = 0usize;
    for (b, r) in &candidates {
        let flag = if r.force() { "-D" } else { "-d" };
        print!("Deleting {} ({})... ", b.name, r.label());
        io::Write::flush(&mut io::stdout())?;
        let output = Command::new("git")
            .current_dir(&main_repo)
            .arg("branch")
            .arg(flag)
            .arg(&b.name)
            .output()
            .await
            .context("Failed to spawn git branch")?;
        if output.status.success() {
            println!("✓");
            deleted += 1;
        } else {
            let stderr = String::from_utf8_lossy(&output.stderr);
            println!("✗ ({})", stderr.trim());
            failed += 1;
        }
    }

    println!(
        "\nDeleted {}/{} branches{}",
        deleted,
        candidates.len(),
        if failed > 0 {
            format!(", {} failed", failed)
        } else {
            String::new()
        }
    );

    Ok(())
}
