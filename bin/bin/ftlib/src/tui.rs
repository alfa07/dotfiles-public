//! Interactive terminal UI: the skim fuzzy finder used by `ft go`, and the
//! ratatui cleanup checklist used by `ft clean`. Multiplexer-agnostic: it
//! renders `Container`s instead of tmux windows.

use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph},
    Frame, Terminal,
};
use std::io;

use crate::feature::{CiStatus, Feature, FeatureKind, FeatureStatus};
use crate::mux::{AgentStatus, Container};

pub struct CleanupItem {
    pub feature: Feature,
    pub status: FeatureStatus,
    pub selected: bool,
    pub containers: Vec<Container>,
    pub has_open: bool,
}

pub fn run_fuzzy_finder(items: &[String]) -> Result<Option<String>> {
    use skim::prelude::*;
    use std::io::Cursor;

    let options = SkimOptionsBuilder::default()
        .height(Some("50%"))
        .multi(false)
        .prompt(Some("Select feature> "))
        .build()
        .unwrap();

    let input = items.join("\n");
    let item_reader = SkimItemReader::default();
    let items = item_reader.of_bufread(Cursor::new(input));

    let output = Skim::run_with(&options, Some(items));

    match output {
        Some(out) if !out.is_abort => {
            let selected = out
                .selected_items
                .first()
                .map(|item| item.output().to_string());
            Ok(selected)
        }
        _ => Ok(None),
    }
}

pub fn run_cleanup_tui(items: Vec<CleanupItem>) -> Result<Vec<CleanupItem>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let result = run_tui_loop(&mut terminal, items);

    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    result
}

fn run_tui_loop(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    mut items: Vec<CleanupItem>,
) -> Result<Vec<CleanupItem>> {
    let mut state = ListState::default();
    state.select(Some(0));

    loop {
        terminal.draw(|f| render_ui(f, &items, &mut state))?;

        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Char('q') | KeyCode::Esc => {
                    return Ok(Vec::new());
                }
                KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                    return Ok(Vec::new());
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    let i = state.selected().unwrap_or(0);
                    if i < items.len() - 1 {
                        state.select(Some(i + 1));
                    }
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    let i = state.selected().unwrap_or(0);
                    if i > 0 {
                        state.select(Some(i - 1));
                    }
                }
                KeyCode::Char(' ') => {
                    if let Some(i) = state.selected() {
                        if i < items.len() {
                            items[i].selected = !items[i].selected;
                        }
                    }
                }
                KeyCode::Enter => {
                    return Ok(items.into_iter().filter(|item| item.selected).collect());
                }
                _ => {}
            }
        }
    }
}

fn render_ui(f: &mut Frame, items: &[CleanupItem], state: &mut ListState) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(2),
            Constraint::Min(5),
            Constraint::Length(2),
        ])
        .split(f.area());

    let header = Paragraph::new("ft cleanup — feature clones & legacy worktrees")
        .block(Block::default().borders(Borders::ALL));

    f.render_widget(header, chunks[0]);

    let list_items: Vec<ListItem> = items
        .iter()
        .map(|item| {
            let branch_name = item.feature.branch_name();

            let checkbox = if item.selected { "[✓]" } else { "[ ]" };

            let kind_tag = match item.feature.kind {
                FeatureKind::Clone => Span::styled(" [clone]", Style::default().fg(Color::Blue)),
                FeatureKind::Worktree => {
                    Span::styled(" [worktree]", Style::default().fg(Color::DarkGray))
                }
            };

            let status_tag = if item.status.is_landed {
                Span::styled(" [LANDED]", Style::default().fg(Color::Green))
            } else {
                Span::styled(" [ACTIVE]", Style::default().fg(Color::Yellow))
            };

            let pr_text = if let Some(ref pr) = item.status.pr_info {
                let ci_symbol = match pr.ci_status {
                    CiStatus::Success => "✓",
                    CiStatus::Failure => "✗",
                    CiStatus::Pending => "⊙",
                    CiStatus::None => "-",
                };
                format!("  PR #{} {}", pr.number, ci_symbol)
            } else {
                String::new()
            };

            let uncommitted_text = if item.status.uncommitted_count > 0 {
                format!("⚠ {} uncommitted  |  ", item.status.uncommitted_count)
            } else {
                "Clean  |  ".to_string()
            };

            let diff_text = format!("+{}/{} vs main", item.status.insertions, item.status.deletions);

            let container_text = match item.containers.len() {
                0 => "  |  no containers".to_string(),
                1 => format!("  |  {}", item.containers[0].display),
                n => format!("  |  {} containers", n),
            };

            // Agent state (herdr only) shown next to the OPEN marker.
            let agent_tag = match item
                .containers
                .first()
                .and_then(|c| c.agent_status)
                .filter(|s| *s != AgentStatus::Unknown)
            {
                Some(s) => {
                    let color = match s {
                        AgentStatus::Blocked => Color::Red,
                        AgentStatus::Working => Color::Yellow,
                        AgentStatus::Done => Color::Green,
                        _ => Color::DarkGray,
                    };
                    Span::styled(format!(" {} {}", s.glyph(), s.label()), Style::default().fg(color))
                }
                None => Span::raw(""),
            };

            let open_tag = if item.has_open {
                Span::styled(" [OPEN]", Style::default().fg(Color::Magenta))
            } else {
                Span::raw("")
            };

            let line1 = Line::from(vec![
                Span::raw(format!("{} ", checkbox)),
                Span::raw(branch_name.to_string()),
                kind_tag,
                status_tag,
                open_tag,
                agent_tag,
                Span::styled(pr_text, Style::default().fg(Color::Cyan)),
            ]);

            let line2 = Line::from(format!("    {}", item.feature.path.display()));

            let line3 = Line::from(format!("    {}{}{}", uncommitted_text, diff_text, container_text));

            ListItem::new(vec![line1, line2, line3, Line::from("")])
        })
        .collect();

    let list = List::new(list_items)
        .block(Block::default().borders(Borders::ALL))
        .highlight_style(Style::default().add_modifier(Modifier::REVERSED));

    f.render_stateful_widget(list, chunks[1], state);

    let selected_count = items.iter().filter(|i| i.selected).count();
    let total_containers: usize = items.iter().filter(|i| i.selected).map(|i| i.containers.len()).sum();
    let landed_count = items.iter().filter(|i| i.selected && i.status.is_landed).count();
    let active_count = selected_count - landed_count;

    let summary = if selected_count > 0 {
        format!(
            "{} feature(s) + {} container(s) selected  |  {} landed, {} active",
            selected_count, total_containers, landed_count, active_count
        )
    } else {
        "No features selected".to_string()
    };

    let footer = Paragraph::new(Line::from(vec![
        Span::styled(" ↑↓ ", Style::default().fg(Color::Black).bg(Color::Gray)),
        Span::raw(" navigate "),
        Span::styled(" SPACE ", Style::default().fg(Color::Black).bg(Color::Gray)),
        Span::raw(" toggle "),
        Span::styled(" ENTER ", Style::default().fg(Color::Black).bg(Color::Gray)),
        Span::raw(" confirm "),
        Span::styled(" q ", Style::default().fg(Color::Black).bg(Color::Gray)),
        Span::raw(" quit  │  "),
        Span::styled(&summary, Style::default().fg(Color::Cyan)),
    ]));

    f.render_widget(footer, chunks[2]);
}
