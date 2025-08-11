use anyhow::{anyhow, Context, Result};
use regex::Regex;
use std::collections::{BTreeSet, HashMap};
use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use which::which;

const APP_NAME: &str = "GNOME Monitor TUI";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum UIKind { Dialog, Whiptail, Plain }

fn have(cmd: &str) -> bool { which(cmd).is_ok() }

fn detect_ui() -> UIKind {
    if have("dialog") { UIKind::Dialog }
    else if have("whiptail") { UIKind::Whiptail }
    else { UIKind::Plain }
}

fn msgbox(ui: UIKind, text: &str) {
    match ui {
        UIKind::Dialog => { let _ = Command::new("dialog").arg("--title").arg(APP_NAME).arg("--msgbox").arg(text).arg("10").arg("70").status(); },
        UIKind::Whiptail => { let _ = Command::new("whiptail").arg("--title").arg(APP_NAME).arg("--msgbox").arg(text).arg("10").arg("70").status(); },
        UIKind::Plain => {
            println!("\n== {} ==\n{}\n", APP_NAME, text);
            let _ = prompt_enter();
        }
    }
}

fn inputbox(ui: UIKind, prompt: &str, default: &str) -> Result<String> {
    Ok(match ui {
        UIKind::Dialog => {
            let out = Command::new("dialog")
                .arg("--title").arg(APP_NAME)
                .arg("--stdout")
                .arg("--inputbox").arg(prompt).arg("10").arg("70").arg(default)
                .output()?;
            String::from_utf8_lossy(&out.stdout).trim().to_string()
        }
        UIKind::Whiptail => {
            let out = Command::new("whiptail")
                .arg("--title").arg(APP_NAME)
                .arg("--inputbox").arg(prompt).arg("10").arg("70").arg(default)
                .arg("--output-fd").arg("1")
                .output()?;
            String::from_utf8_lossy(&out.stdout).trim().to_string()
        }
        UIKind::Plain => {
            print!("{} [{}]: ", prompt, default);
            io::stdout().flush()?;
            let mut s = String::new();
            io::stdin().read_line(&mut s)?;
            let s = s.trim();
            if s.is_empty() { default.to_string() } else { s.to_string() }
        }
    })
}

fn menu(ui: UIKind, prompt: &str, options: &[(String, String)]) -> Result<Option<String>> {
    match ui {
        UIKind::Dialog => {
            let mut cmd = Command::new("dialog");
            cmd.arg("--title").arg(APP_NAME).arg("--stdout").arg("--menu").arg(prompt).arg("20").arg("70").arg("12");
            for (k, d) in options { cmd.arg(k).arg(d); }
            let out = cmd.output()?;
            if out.status.success() {
                Ok(Some(String::from_utf8_lossy(&out.stdout).trim().to_string()))
            } else { Ok(None) }
        }
        UIKind::Whiptail => {
            let mut cmd = Command::new("whiptail");
            cmd.arg("--title").arg(APP_NAME).arg("--menu").arg(prompt).arg("20").arg("70").arg("12");
            for (k, d) in options { cmd.arg(k).arg(d); }
            cmd.arg("--output-fd").arg("1");
            let out = cmd.output()?;
            if out.status.success() { Ok(Some(String::from_utf8_lossy(&out.stdout).trim().to_string())) } else { Ok(None) }
        }
        UIKind::Plain => {
            println!("\n{}", prompt);
            for (i, (k, d)) in options.iter().enumerate() { println!("  {}) {}", i+1, d); }
            print!("Choose 1-{}: ", options.len()); io::stdout().flush()?;
            let mut s = String::new(); io::stdin().read_line(&mut s)?; let s = s.trim();
            if s.is_empty() { return Ok(None); }
            if let Ok(ix) = s.parse::<usize>() { if ix>=1 && ix<=options.len() { return Ok(Some(options[ix-1].0.clone())); } }
            Ok(None)
        }
    }
}

fn checklist(ui: UIKind, prompt: &str, items: &[(String, String, bool)]) -> Result<Vec<String>> {
    match ui {
        UIKind::Dialog => {
            let mut cmd = Command::new("dialog");
            cmd.arg("--title").arg(APP_NAME).arg("--stdout").arg("--checklist").arg(prompt).arg("20").arg("70").arg("12");
            for (k, d, on) in items { cmd.arg(k).arg(d).arg(if *on { "ON" } else { "OFF" }); }
            let out = cmd.output()?;
            if out.status.success() {
                let s = String::from_utf8_lossy(&out.stdout);
                Ok(parse_selected(&s))
            } else { Ok(vec![]) }
        }
        UIKind::Whiptail => {
            let mut cmd = Command::new("whiptail");
            cmd.arg("--title").arg(APP_NAME).arg("--checklist").arg(prompt).arg("20").arg("70").arg("12");
            for (k, d, on) in items { cmd.arg(k).arg(d).arg(if *on { "ON" } else { "OFF" }); }
            cmd.arg("--output-fd").arg("1");
            let out = cmd.output()?;
            if out.status.success() { Ok(parse_selected(&String::from_utf8_lossy(&out.stdout))) } else { Ok(vec![]) }
        }
        UIKind::Plain => {
            println!("\n{}", prompt);
            for (i, (k, d, on)) in items.iter().enumerate() {
                println!("  [{}] {} {}", if *on { "x" } else { " " }, i+1, format!("{}  {}", k, d));
            }
            print!("Enter numbers to select (e.g. 1 3): "); io::stdout().flush()?;
            let mut s = String::new(); io::stdin().read_line(&mut s)?; let s = s.trim();
            let mut out = vec![];
            for tok in s.split_whitespace() {
                if let Ok(ix) = tok.parse::<usize>() { if ix>=1 && ix<=items.len() { out.push(items[ix-1].0.clone()); } }
            }
            Ok(out)
        }
    }
}

fn parse_selected(s: &str) -> Vec<String> {
    // dialog/whiptail may quote items. Remove quotes and split
    s.replace('"', "").split_whitespace().map(|t| t.to_string()).collect()
}

fn discover_connectors() -> Vec<String> {
    let mut found = BTreeSet::new();
    let re = Regex::new(r"\b(HDMI|DP|eDP|VGA|DVI|USB-C)(-[0-9]+)\b").unwrap();
    if have("gnome-monitor-config") {
        if let Ok(out) = Command::new("gnome-monitor-config").arg("list").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            for cap in re.captures_iter(&s) { found.insert(cap.get(0).unwrap().as_str().to_string()); }
        }
    }
    if found.is_empty() && have("xrandr") {
        if let Ok(out) = Command::new("xrandr").arg("--listmonitors").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            for cap in re.captures_iter(&s) { found.insert(cap.get(0).unwrap().as_str().to_string()); }
        }
    }
    if found.is_empty() {
        // Fallback: ask user
        let ui = detect_ui();
        let manual = inputbox(ui, "Enter connector names (space-separated):", "DP-3 DP-10 eDP-1").unwrap_or_default();
        for t in manual.split_whitespace() { found.insert(t.to_string()); }
    }
    found.into_iter().collect()
}

fn describe_connector(conn: &str) -> String {
    if have("xrandr") {
        if let Ok(out) = Command::new("xrandr").arg("--query").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            for line in s.lines() {
                if line.starts_with(conn) {
                    let status = line.split_whitespace().nth(1).unwrap_or("");
                    let primary = if line.contains(" primary ") { " primary" } else { "" };
                    let re = Regex::new(r"[0-9]{3,}x[0-9]{3,}\+[0-9]+\+[0-9]+").unwrap();
                    let respos = re.find(line).map(|m| format!(" {}", m.as_str())).unwrap_or_default();
                    let mut desc = format!("[{}{}{}]", status, primary, respos);
                    if conn.starts_with("eDP-") { desc.push_str(" internal"); }
                    return desc;
                }
            }
        }
    }
    if have("gnome-monitor-config") {
        if let Ok(out) = Command::new("gnome-monitor-config").arg("list").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            if s.contains(conn) {
                let re = Regex::new(r"[0-9]{3,}x[0-9]{3,}@?[0-9.]*").unwrap();
                let wh = re.find(&s).map(|m| m.as_str().to_string());
                let mut desc = match wh { Some(w) => format!("[present {}]", w), None => "[present]".to_string() };
                if conn.starts_with("eDP-") { desc.push_str(" internal"); }
                return desc;
            }
        }
    }
    let mut desc = "[present]".to_string();
    if conn.starts_with("eDP-") { desc.push_str(" internal"); }
    desc
}

fn build_command_args(mirror_group: &[String], placement: &str, offy: i32, offx: i32, others: &[String]) -> Vec<String> {
    let mut args: Vec<String> = vec!["set".into()];
    // First logical monitor: PRIMARY group at 0,0
    args.push("-Lp".into());
    for m in mirror_group { args.push("-M".into()); args.push(m.clone()); }
    args.push("-x".into()); args.push("0".into());
    args.push("-y".into()); args.push("0".into());

    for o in others {
        let (x, y) = match placement {
            "below" => (offx, offy),
            "above" => (offx, -offy),
            "right" => (offx, offy),
            "left"  => (-offx, offy),
            _ => (offx, offy),
        };
        args.push("-L".into());
        args.push("-M".into()); args.push(o.clone());
        args.push("-x".into()); args.push(x.to_string());
        args.push("-y".into()); args.push(y.to_string());
    }
    args
}

fn args_to_shell(cmd: &str, args: &[String]) -> String {
    let mut s = String::new(); s.push_str(cmd);
    for a in args { s.push(' '); s.push_str(&shell_escape(a)); }
    s
}

fn shell_escape(s: &str) -> String {
    if s.chars().all(|c| c.is_ascii_alphanumeric() || "-_/.:@".contains(c)) {
        s.to_string()
    } else {
        let escaped = s.replace('\'', "'\\''");
        format!("'{}'", escaped)
    }
}

fn snapshot_dir() -> PathBuf {
    let base = env::var("XDG_CONFIG_HOME").map(PathBuf::from).unwrap_or_else(|_| dirs_home_config());
    base.join("monitor-tui")
}

fn dirs_home_config() -> PathBuf {
    let home = env::var("HOME").map(PathBuf::from).unwrap_or_else(|_| PathBuf::from("."));
    home.join(".config")
}

fn snapshot_save(label: &str, cmdline: &str) -> Result<PathBuf> {
    let dir = snapshot_dir(); fs::create_dir_all(&dir)?;
    let mut name = label.replace(|c: char| c.is_whitespace(), "_");
    name.retain(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-' || c == '.');
    if name.is_empty() { name = format!("snapshot_{}", chrono::Local::now().format("%Y%m%d_%H%M%S")); }
    let file = dir.join(format!("{}.sh", name));
    let content = format!("#!/usr/bin/env bash\nset -euo pipefail\n{}\n", cmdline);
    fs::write(&file, content)?;
    let _ = Command::new("chmod").arg("+x").arg(&file).status();
    Ok(file)
}

fn snapshot_pick(ui: UIKind) -> Result<Option<PathBuf>> {
    let dir = snapshot_dir();
    let mut entries: Vec<PathBuf> = if dir.exists() { fs::read_dir(&dir)?.filter_map(|e| e.ok().map(|e| e.path())).collect() } else { vec![] };
    entries.sort();
    entries.retain(|p| p.extension().map(|e| e == "sh").unwrap_or(false));
    if entries.is_empty() { msgbox(ui, "No snapshots saved yet."); return Ok(None); }
    let mut opts: Vec<(String, String)> = Vec::new();
    for p in &entries { let base = p.file_name().unwrap().to_string_lossy().to_string(); opts.push((base.clone(), "apply/delete".into())); }
    if let Some(sel) = menu(ui, "Snapshots:", &opts)? {
        return Ok(Some(dir.join(sel)));
    }
    Ok(None)
}

fn prompt_enter() -> Result<()> { let mut s = String::new(); io::stdin().read_line(&mut s)?; Ok(()) }

fn main() -> Result<()> {
    let ui = detect_ui();
    if !have("gnome-monitor-config") {
        msgbox(ui, "gnome-monitor-config is required (Wayland). Please install it (part of GNOME). Aborting.");
        return Ok(());
    }

    loop {
        let choice = menu(ui, "Choose an action:", &[
            ("new".into(), "Create & apply a new layout".into()),
            ("apply".into(), "Apply a saved snapshot".into()),
            ("delete".into(), "Delete a saved snapshot".into()),
            ("quit".into(), "Quit".into()),
        ])?;
        match choice.as_deref() {
            Some("new") => new_layout(ui)?,
            Some("apply") => { if let Some(p) = snapshot_pick(ui)? { let _ = Command::new("bash").arg(p).status(); } },
            Some("delete") => { if let Some(p) = snapshot_pick(ui)? { let _ = fs::remove_file(&p); msgbox(ui, &format!("Deleted snapshot: {}", p.file_name().unwrap().to_string_lossy())); } },
            Some("quit") | None => break,
            _ => {}
        }
    }
    Ok(())
}

fn new_layout(ui: UIKind) -> Result<()> {
    let conns = discover_connectors();
    let mut cl_args: Vec<(String, String, bool)> = Vec::new();
    for c in &conns { cl_args.push((c.clone(), describe_connector(c), false)); }
    let picked = checklist(ui, "Pick one or more connectors to MIRROR as a single logical monitor (these will be your 'big' display):", &cl_args)?;
    if picked.is_empty() { msgbox(ui, "You must select at least one connector."); return Ok(()); }

    // Summary
    let mut summary = String::new();
    for c in &conns { summary.push_str(&format!("{} {}\n", c, describe_connector(c))); }
    msgbox(ui, &format!("Detected connectors:\n{}", summary));

    let place = match menu(ui, "Where do you want to place the OTHER monitors relative to the mirrored group?", &[
        ("below".into(), "Below (typical laptop-under-desktop)".into()),
        ("above".into(), "Above".into()),
        ("left".into(), "Left".into()),
        ("right".into(), "Right".into()),
    ])? { Some(p) => p, None => return Ok(()) };

    let offy: i32 = inputbox(ui, "Pixel offset for Y (distance from mirrored group). Example: 2160", "2160")?.parse().unwrap_or(2160);
    let offx: i32 = inputbox(ui, "Pixel offset for X. Example: 0", "0")?.parse().unwrap_or(0);

    let pick_set: BTreeSet<String> = picked.iter().cloned().collect();
    let mut others: Vec<String> = conns.iter().filter(|c| !pick_set.contains(*c)).cloned().collect();

    if !others.is_empty() {
        let mut cl2: Vec<(String, String, bool)> = Vec::new();
        for o in &others { cl2.push((o.clone(), describe_connector(o), true)); }
        let picked2 = checklist(ui, &format!("Select which of the remaining connectors to include (they will be placed {} the group):", place), &cl2)?;
        others = picked2;
    }

    let args = build_command_args(&picked, &place, offy, offx, &others);
    let status = Command::new("gnome-monitor-config").args(&args).status()?;
    let cmdline = args_to_shell("gnome-monitor-config", &args);
    if status.success() {
        msgbox(ui, &format!("Applied:\n{}", cmdline));
        if let Some(ans) = menu(ui, "Snapshot this working layout?", &[("yes".into(), "Save snapshot".into()), ("no".into(), "Skip".into())])? {
            if ans == "yes" {
                let default = format!("mirrored_group_{}", chrono::Local::now().format("%Y%m%d_%H%M%S"));
                let label = inputbox(ui, "Snapshot label:", &default)?;
                let file = snapshot_save(&label, &cmdline)?;
                msgbox(ui, &format!("Saved snapshot: {}", file.display()));
            }
        }
    } else {
        msgbox(ui, &format!("Failed to apply the layout.\nCommand was:\n{}", cmdline));
    }

    Ok(())
}
