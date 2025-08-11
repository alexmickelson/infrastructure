use anyhow::Result;
use console::style;
use dialoguer::{theme::ColorfulTheme, Input, MultiSelect, Select};
use std::io;

const APP_NAME: &str = "GNOME Monitor TUI";

fn theme() -> ColorfulTheme {
    let mut t = ColorfulTheme::default();
    // Slightly more vivid selection and success colors for a modern feel
    t.values_style = t.values_style.bold();
    t.active_item_style = t.active_item_style.bold();
    // Customize prefixes for a cleaner, modern aesthetic
    t.prompt_prefix = style("❯".to_string());
    t.success_prefix = style("✔".to_string());
    t.error_prefix = style("✘".to_string());
    t.active_item_prefix = style("➤".to_string());
    t.inactive_item_prefix = style(" ".to_string());
    t.checked_item_prefix = style("◉".to_string());
    t.unchecked_item_prefix = style("○".to_string());
    t.picked_item_prefix = style("⭐".to_string());
    t.unpicked_item_prefix = style(" ".to_string());
    t
}

pub fn msgbox(text: &str) {
    let bar = "═".repeat(64);
    println!("\n╔{}╗\n║ {:<62} ║\n╚{}╝\n", bar, APP_NAME, bar);
    println!("{}\n", text);
    let _ = prompt_enter();
}

pub fn inputbox(prompt: &str, default: &str) -> Result<String> {
    Ok(Input::with_theme(&theme())
        .with_prompt(prompt)
        .default(default.to_string())
        .interact_text()?)
}

pub fn menu(prompt: &str, options: &[(String, String)]) -> Result<Option<String>> {
    let items: Vec<String> = options.iter().map(|(_, d)| d.clone()).collect();
    let idx = Select::with_theme(&theme())
        .with_prompt(prompt)
        .items(&items)
        .default(0)
        .interact_opt()?;
    Ok(idx.map(|i| options[i].0.clone()))
}

pub fn checklist(prompt: &str, items: &[(String, String, bool)]) -> Result<Vec<String>> {
    let labels: Vec<String> = items
        .iter()
        .map(|(k, d, _)| format!("{}  {}", k, d))
        .collect();
    let defaults: Vec<bool> = items.iter().map(|(_, _, on)| *on).collect();
    let chosen = MultiSelect::with_theme(&theme())
        .with_prompt(prompt)
        .items(&labels)
        .defaults(&defaults)
        .interact()?;
    Ok(chosen.into_iter().map(|i| items[i].0.clone()).collect())
}

pub fn prompt_enter() -> Result<()> {
    let mut s = String::new();
    io::stdin().read_line(&mut s)?;
    Ok(())
}
