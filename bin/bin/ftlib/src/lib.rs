//! `ftlib` — the implementation behind the thin `~/bin/ft` rust-script.
//!
//! `ft` manages git feature-clones (each on its own branch under `<repo>/.wt/`)
//! and gives each one a terminal container running Claude Code. The container is
//! provided by a pluggable [`mux::Multiplexer`] backend (herdr or tmux), chosen
//! at startup by [`mux::Multiplexer::detect`].

pub mod cargo_setup;
pub mod cli;
pub mod commands;
pub mod feature;
pub mod git;
pub mod mux;
pub mod tui;

use clap::Parser;

use cli::{Cli, Commands};
use mux::Multiplexer;

/// Entry point for the thin script: build the async runtime, dispatch the
/// command, and map any error to a process exit code.
pub fn run() -> std::process::ExitCode {
    match dispatch() {
        Ok(()) => std::process::ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("Error: {:#}", e);
            std::process::ExitCode::FAILURE
        }
    }
}

#[tokio::main]
async fn dispatch() -> anyhow::Result<()> {
    let cli = Cli::parse();
    let mux = Multiplexer::detect();

    match cli.command {
        Commands::New { feature } => commands::cmd_new(&mux, &feature).await,
        Commands::Clean => commands::cmd_clean(&mux).await,
        Commands::Go { feature } => commands::cmd_go(&mux, &feature).await,
        Commands::Restore => commands::cmd_restore(&mux).await,
        Commands::CleanStaleBranches { no_fetch, yes } => {
            commands::cmd_clean_stale_branches(no_fetch, yes).await
        }
    }
}
