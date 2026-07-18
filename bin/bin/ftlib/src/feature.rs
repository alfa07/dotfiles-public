//! Core data types describing feature clones/worktrees and their status.
//! These are pure data, decoupled from git, the multiplexer, and the TUI.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FeatureKind {
    Worktree,
    Clone,
}

impl FeatureKind {
    pub fn label(self) -> &'static str {
        match self {
            FeatureKind::Worktree => "worktree",
            FeatureKind::Clone => "clone",
        }
    }
}

#[derive(Debug, Clone)]
pub struct Feature {
    pub path: PathBuf,
    pub kind: FeatureKind,
    pub branch: String,
    pub commit: String,
    pub is_current: bool,
}

impl Feature {
    /// Branch name without the `refs/heads/` prefix.
    pub fn branch_name(&self) -> &str {
        self.branch
            .strip_prefix("refs/heads/")
            .unwrap_or(&self.branch)
    }
}

#[derive(Debug, Clone)]
pub struct FeatureStatus {
    pub uncommitted_count: usize,
    pub _files_changed: usize,
    pub insertions: usize,
    pub deletions: usize,
    pub is_landed: bool,
    pub pr_info: Option<PrInfo>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrInfo {
    pub number: u32,
    pub url: String,
    pub ci_status: CiStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CiStatus {
    Success,
    Failure,
    Pending,
    None,
}

#[derive(Debug, Clone)]
pub struct BranchInfo {
    pub name: String,
    pub track: String,
    pub worktree_path: String,
    pub subject: String,
}

#[derive(Debug, Clone, Copy)]
pub enum StaleReason {
    Gone,
    Merged,
    GoneAndMerged,
}

impl StaleReason {
    pub fn label(self) -> &'static str {
        match self {
            StaleReason::Gone => "gone",
            StaleReason::Merged => "merged",
            StaleReason::GoneAndMerged => "gone+merged",
        }
    }

    pub fn force(self) -> bool {
        matches!(self, StaleReason::Gone | StaleReason::GoneAndMerged)
    }
}
