use anyhow::Result;
use crossterm::{
    event::{self, Event, KeyCode, KeyEvent, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Modifier, Style},
    text::{Line, Span, Text},
    widgets::{Block, Borders, Clear, List, ListItem, Padding, Paragraph, Wrap},
    Terminal,
};
use std::io::{self, stdout};

const APP_NAME: &str = "GNOME Monitor TUI";

fn with_terminal<F, T>(mut f: F) -> Result<T>
where
    F: FnMut(&mut Terminal<CrosstermBackend<io::Stdout>>) -> Result<T>,
{
    enable_raw_mode()?;
    let mut out = stdout();
    execute!(out, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(out);
    let mut terminal = Terminal::new(backend)?;
    terminal.clear()?;

    let res = f(&mut terminal);

    disable_raw_mode()?;
    // It's okay if leaving alternate screen fails after rendering; try best-effort
    let _ = execute!(terminal.backend_mut(), LeaveAlternateScreen);
    let _ = terminal.show_cursor();
    res
}

fn center_rect(percent_x: u16, percent_y: u16, area: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(area);

    let vertical = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1]);

    vertical[1]
}

pub fn msgbox(text: &str) {
    let _ = with_terminal(|t| {
        loop {
            t.draw(|f| {
                let area = center_rect(80, 50, f.size());
                let block = Block::default()
                    .title(APP_NAME)
                    .borders(Borders::ALL)
                    .padding(Padding::uniform(1));
                let content = Paragraph::new(Text::from(text.to_string()))
                    .block(block)
                    .wrap(Wrap { trim: true })
                    .alignment(Alignment::Left);
                let hint = Paragraph::new(Line::from(vec![
                    Span::raw("Press "),
                    Span::styled("Enter", Style::default().add_modifier(Modifier::BOLD)),
                    Span::raw(" to continue"),
                ]))
                .alignment(Alignment::Center);

                f.render_widget(Clear, area);
                f.render_widget(content, area);
                let hint_area = Rect {
                    x: area.x,
                    y: area.y + area.height.saturating_sub(2),
                    width: area.width,
                    height: 1,
                };
                f.render_widget(hint, hint_area);
            })?;

            if let Event::Key(KeyEvent { code, .. }) = event::read()? {
                match code {
                    KeyCode::Enter | KeyCode::Esc => break,
                    _ => {}
                }
            }
        }
        Ok(())
    });
}

pub fn inputbox(prompt: &str, default: &str) -> Result<String> {
    let mut value = default.to_string();
    with_terminal(|t| {
        loop {
            t.draw(|f| {
                let area = center_rect(80, 40, f.size());
                let block = Block::default()
                    .title(APP_NAME)
                    .borders(Borders::ALL)
                    .padding(Padding::uniform(1));

                let mut lines = Vec::new();
                lines.push(Line::from(Span::styled(
                    prompt,
                    Style::default().add_modifier(Modifier::BOLD),
                )));
                lines.push(Line::from(""));
                lines.push(Line::from(value.clone()));
                lines.push(Line::from(""));
                lines.push(Line::from("Enter to accept, Esc to cancel"));

                let content = Paragraph::new(Text::from(lines))
                    .block(block)
                    .wrap(Wrap { trim: false })
                    .alignment(Alignment::Left);

                f.render_widget(Clear, area);
                f.render_widget(content, area);
                // place cursor at input line end
                let cursor_x = area.x + value.len() as u16;
                let cursor_y = area.y + 2; // third line
                f.set_cursor(
                    cursor_x.min(area.x + area.width.saturating_sub(2)),
                    cursor_y,
                );
            })?;

            match event::read()? {
                Event::Key(KeyEvent {
                    code, modifiers, ..
                }) => match code {
                    KeyCode::Enter => break,
                    KeyCode::Esc => {
                        value = default.to_string();
                        break;
                    }
                    KeyCode::Backspace => {
                        value.pop();
                    }
                    KeyCode::Char('u') if modifiers.contains(KeyModifiers::CONTROL) => {
                        value.clear();
                    }
                    KeyCode::Char(c) => value.push(c),
                    _ => {}
                },
                _ => {}
            }
        }
        Ok(value.clone())
    })
}

pub fn menu(prompt: &str, options: &[(String, String)]) -> Result<Option<String>> {
    if options.is_empty() {
        return Ok(None);
    }
    let mut selected: usize = 0;
    with_terminal(|t| {
        loop {
            t.draw(|f| {
                let area = center_rect(80, 70, f.size());
                let block = Block::default()
                    .title(APP_NAME)
                    .borders(Borders::ALL)
                    .padding(Padding::uniform(1));

                let mut text = Vec::new();
                text.push(Line::from(Span::styled(
                    prompt,
                    Style::default().add_modifier(Modifier::BOLD),
                )));
                text.push(Line::from(""));

                let items: Vec<ListItem> = options
                    .iter()
                    .enumerate()
                    .map(|(i, (_, d))| {
                        let prefix = if i == selected { "➤ " } else { "  " };
                        ListItem::new(format!("{}{}", prefix, d))
                    })
                    .collect();

                let list = List::new(items)
                    .block(block)
                    .highlight_symbol("➤ ")
                    .highlight_style(Style::default().add_modifier(Modifier::BOLD));

                f.render_widget(Clear, area);
                // Render prompt at top area
                let top = Rect {
                    x: area.x,
                    y: area.y,
                    width: area.width,
                    height: 2,
                };
                let prompt_para = Paragraph::new(Text::from(text)).alignment(Alignment::Left);
                f.render_widget(prompt_para, top);
                // Render list below
                let list_area = Rect {
                    x: area.x,
                    y: area.y + 2,
                    width: area.width,
                    height: area.height.saturating_sub(2),
                };
                f.render_widget(list, list_area);
            })?;

            if let Event::Key(KeyEvent { code, .. }) = event::read()? {
                match code {
                    KeyCode::Up => {
                        if selected > 0 {
                            selected -= 1;
                        }
                    }
                    KeyCode::Down => {
                        if selected + 1 < options.len() {
                            selected += 1;
                        }
                    }
                    KeyCode::Enter => return Ok(Some(options[selected].0.clone())),
                    KeyCode::Esc => return Ok(None),
                    _ => {}
                }
            }
        }
    })
}

pub fn checklist(prompt: &str, items: &[(String, String, bool)]) -> Result<Vec<String>> {
    if items.is_empty() {
        return Ok(vec![]);
    }
    let mut active: usize = 0;
    let mut checked: Vec<bool> = items.iter().map(|(_, _, on)| *on).collect();

    with_terminal(|t| loop {
        t.draw(|f| {
            let area = center_rect(80, 80, f.size());
            let block = Block::default()
                .title(APP_NAME)
                .borders(Borders::ALL)
                .padding(Padding::uniform(1));

            let prompt_para = Paragraph::new(Text::from(vec![
                Line::from(Span::styled(
                    prompt,
                    Style::default().add_modifier(Modifier::BOLD),
                )),
                Line::from(""),
                Line::from("Use ↑/↓ to move, Space to toggle, Enter to confirm, Esc to cancel"),
            ]))
            .alignment(Alignment::Left);

            let list_items: Vec<ListItem> = items
                .iter()
                .enumerate()
                .map(|(i, (k, d, _))| {
                    let mark = if checked[i] { "[x]" } else { "[ ]" };
                    let cursor = if i == active { "➤" } else { " " };
                    ListItem::new(format!("{} {} {}  {}", cursor, mark, k, d))
                })
                .collect();

            let list = List::new(list_items)
                .block(block)
                .highlight_symbol("➤ ")
                .highlight_style(Style::default().add_modifier(Modifier::BOLD));

            f.render_widget(Clear, area);
            let top = Rect {
                x: area.x,
                y: area.y,
                width: area.width,
                height: 3,
            };
            f.render_widget(prompt_para, top);
            let list_area = Rect {
                x: area.x,
                y: area.y + 3,
                width: area.width,
                height: area.height.saturating_sub(3),
            };
            f.render_widget(list, list_area);
        })?;

        if let Event::Key(KeyEvent { code, .. }) = event::read()? {
            match code {
                KeyCode::Up => {
                    if active > 0 {
                        active -= 1;
                    }
                }
                KeyCode::Down => {
                    if active + 1 < items.len() {
                        active += 1;
                    }
                }
                KeyCode::Char(' ') => {
                    checked[active] = !checked[active];
                }
                KeyCode::Enter => {
                    let out: Vec<String> = items
                        .iter()
                        .enumerate()
                        .filter_map(
                            |(i, (k, _, _))| if checked[i] { Some(k.clone()) } else { None },
                        )
                        .collect();
                    return Ok(out);
                }
                KeyCode::Esc => return Ok(vec![]),
                _ => {}
            }
        }
    })
}
