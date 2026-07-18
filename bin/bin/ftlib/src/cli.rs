//! Command-line surface (clap derive). Mirrors the original `ft` CLI.

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "ft")]
#[command(about = "Git feature-clone (and legacy worktree) management tool", long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    #[command(about = "Create a feature clone and launch Claude Code (herdr or tmux)")]
    New {
        #[arg(help = "Feature branch name")]
        feature: String,
    },
    #[command(about = "Interactive cleanup of landed feature clones/worktrees")]
    Clean,
    #[command(about = "Switch to the container for a feature branch")]
    Go {
        #[arg(help = "Feature branch name (optional - shows fuzzy finder if omitted)")]
        feature: Option<String>,
    },
    #[command(about = "Recreate multiplexer containers for features that lack one")]
    Restore,
    #[command(about = "Delete local branches that are merged into main or whose upstream is gone")]
    CleanStaleBranches {
        #[arg(long, help = "Skip git fetch --all --prune before classifying")]
        no_fetch: bool,
        #[arg(long, short = 'y', help = "Skip the y/N confirmation prompt")]
        yes: bool,
    },
}
