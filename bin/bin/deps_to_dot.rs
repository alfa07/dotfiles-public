#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4.4.2", features = ["derive"] }
//! ```
use std::collections::HashMap;
use std::collections::HashSet;
use std::io::{self, BufRead};

use clap::Parser;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    /// List of modules to exclude, separated by ","
    #[arg(short, long)]
    exclude: Vec<String>,
}

fn main() {
    let cli = Cli::parse();
    let stdin = io::stdin();
    let mut input_lines = stdin.lock().lines();

    let excludes = cli
        .exclude
        .iter()
        .flat_map(|x| x.split(",").map(String::from).collect::<Vec<_>>())
        .collect::<HashSet<_>>();
    eprintln!("excludes: {:?}", excludes);
    let mut dependencies: HashMap<String, HashSet<String>> = Default::default();

    while let Some(Ok(line)) = input_lines.next() {
        let Some((path, dependency)) = line.split_once(":") else {
            continue;
        };
        let Some(dependency) = dependency.strip_prefix("use ") else {
            continue;
        };
        let parts: Vec<&str> = path.split('/').collect();

        let current_module1 = if parts.len() > 1 {
            parts[parts.len() - 2]
        } else {
            "crate".into()
        };
        let current_module2 = parts.last().unwrap().replace(".rs", "");
        let current_module = format!("{}::{}", current_module1, current_module2);

        let dep_parts: Vec<&str> = dependency.split("::").collect();
        if excludes.contains(dep_parts[0]) {
            continue;
        }
        // println!("{} -> {:?}", current_module, dep_parts);
        if dep_parts.len() > 2 {
            let module1 = dep_parts[dep_parts.len() - 3]
                .replace(";", "")
                .replace("{", "")
                .replace("}", "");
            let module1 = if module1 == "super" {
                current_module1.to_string()
            } else {
                module1.clone()
            };
            let module2 = dep_parts[dep_parts.len() - 2]
                .replace(";", "")
                .replace("{", "")
                .replace("}", "");
            let module = format!("{}::{}", module1, module2);
            dependencies
                .entry(current_module.clone())
                .or_default()
                .insert(module);
        }
    }

    let mut seen = HashSet::new();
    println!("digraph G {{");
    println!("  node [fontname=\"Courier\"];");
    println!("  node [shape=box];");
    println!("  node [labelloc=l];");

    let to_id = |s: &String| -> String { s.replace("::", "__") };

    for (module, deps) in &dependencies {
        if !seen.contains(module) {
            println!("  {} [label=\"{}\"];", to_id(module), module);
            seen.insert(module.clone());
        }
        for dep in deps {
            if !seen.contains(dep) {
                println!("  {} [label=\"{}\"];", to_id(dep), dep);
                seen.insert(dep.clone());
            }
            println!("  {} -> {};", to_id(module), to_id(dep));
        }
    }

    println!("}}");
}
