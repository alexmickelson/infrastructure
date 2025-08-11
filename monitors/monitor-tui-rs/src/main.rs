use anyhow::{anyhow, Context, Result};
use regex::Regex;
use std::collections::{BTreeSet, HashMap};
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use which::which;

mod ui_utils;
use ui_utils::{checklist, inputbox, menu, msgbox};

fn have(cmd: &str) -> bool {
    which(cmd).is_ok()
}

fn discover_connectors() -> Vec<String> {
    let mut found = BTreeSet::new();
    let re = Regex::new(r"\b(HDMI|DP|eDP|VGA|DVI|USB-C)(-[0-9]+)\b").unwrap();
    if have("gnome-monitor-config") {
        if let Ok(out) = Command::new("gnome-monitor-config").arg("list").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            for cap in re.captures_iter(&s) {
                found.insert(cap.get(0).unwrap().as_str().to_string());
            }
        }
    }
    if found.is_empty() && have("xrandr") {
        if let Ok(out) = Command::new("xrandr").arg("--listmonitors").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            for cap in re.captures_iter(&s) {
                found.insert(cap.get(0).unwrap().as_str().to_string());
            }
        }
    }
    if found.is_empty() {
        let manual = inputbox(
            "Enter connector names (space-separated):",
            "DP-3 DP-10 eDP-1",
        )
        .unwrap_or_default();
        for t in manual.split_whitespace() {
            found.insert(t.to_string());
        }
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
                    let primary = if line.contains(" primary ") {
                        " primary"
                    } else {
                        ""
                    };
                    let re = Regex::new(r"[0-9]{3,}x[0-9]{3,}\+[0-9]+\+[0-9]+").unwrap();
                    let respos = re
                        .find(line)
                        .map(|m| format!(" {}", m.as_str()))
                        .unwrap_or_default();
                    let mut desc = format!("[{}{}{}]", status, primary, respos);
                    if conn.starts_with("eDP-") {
                        desc.push_str(" internal");
                    }
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
                let mut desc = match wh {
                    Some(w) => format!("[present {}]", w),
                    None => "[present]".to_string(),
                };
                if conn.starts_with("eDP-") {
                    desc.push_str(" internal");
                }
                return desc;
            }
        }
    }
    let mut desc = "[present]".to_string();
    if conn.starts_with("eDP-") {
        desc.push_str(" internal");
    }
    desc
}

// Detect current resolution (width, height) for a connector, best-effort.
fn connector_size(conn: &str) -> Option<(i32, i32)> {
    // Try xrandr first (has precise current mode with +pos)
    if have("xrandr") {
        if let Ok(out) = Command::new("xrandr").arg("--query").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            for line in s.lines() {
                if line.starts_with(conn) {
                    let re = Regex::new(r"([0-9]{3,})x([0-9]{3,})").ok()?;
                    if let Some(c) = re.captures(line) {
                        let w: i32 = c.get(1)?.as_str().parse().ok()?;
                        let h: i32 = c.get(2)?.as_str().parse().ok()?;
                        return Some((w, h));
                    }
                }
            }
        }
    }
    // Fallback: parse gnome-monitor-config list near the connector name
    if have("gnome-monitor-config") {
        if let Ok(out) = Command::new("gnome-monitor-config").arg("list").output() {
            let s = String::from_utf8_lossy(&out.stdout);
            if let Some(idx) = s.find(conn) {
                let end = (idx + 200).min(s.len());
                let window = &s[idx..end];
                if let Some(c) = Regex::new(r"([0-9]{3,})x([0-9]{3,})")
                    .ok()
                    .and_then(|re| re.captures(window))
                {
                    let w: i32 = c.get(1)?.as_str().parse().ok()?;
                    let h: i32 = c.get(2)?.as_str().parse().ok()?;
                    return Some((w, h));
                }
            }
        }
    }
    None
}

fn group_size(conns: &[String]) -> (i32, i32) {
    let mut max_w = 1920i32;
    let mut max_h = 1080i32;
    for c in conns {
        if let Some((w, h)) = connector_size(c) {
            if w > max_w {
                max_w = w;
            }
            if h > max_h {
                max_h = h;
            }
        }
    }
    (max_w, max_h)
}

fn build_command_args_auto(
    mirror_group: &[String],
    placement: &str,
    others: &[String],
) -> Vec<String> {
    let (gw, gh) = group_size(mirror_group);
    let mut args: Vec<String> = vec!["set".into()];
    // Primary logical monitor (mirrored group) at 0,0
    args.push("-Lp".into());
    for m in mirror_group {
        args.push("-M".into());
        args.push(m.clone());
    }
    args.push("-x".into());
    args.push("0".into());
    args.push("-y".into());
    args.push("0".into());

    // Tile the remaining monitors relative to the group size
    let mut cur_x = 0i32;
    let mut cur_y = 0i32;
    for o in others {
        let (ow, oh) = connector_size(o).unwrap_or((1920, 1080));
        let (x, y) = match placement {
            "right" => {
                let pos = (gw, cur_y);
                cur_y += oh;
                pos
            }
            "left" => {
                let pos = (-ow, cur_y);
                cur_y += oh;
                pos
            }
            "below" => {
                let pos = (cur_x, gh);
                cur_x += ow;
                pos
            }
            "above" => {
                let pos = (cur_x, -oh);
                cur_x += ow;
                pos
            }
            _ => (gw, 0),
        };
        args.push("-L".into());
        args.push("-M".into());
        args.push(o.clone());
        args.push("-x".into());
        args.push(x.to_string());
        args.push("-y".into());
        args.push(y.to_string());
    }
    args
}

// Build args for the CURRENT layout by parsing xrandr --query (best-effort)
fn current_layout_args() -> Option<Vec<String>> {
    if !have("xrandr") {
        return None;
    }
    let out = Command::new("xrandr").arg("--query").output().ok()?;
    let s = String::from_utf8_lossy(&out.stdout);
    let geom_re = Regex::new(r"([0-9]{3,})x([0-9]{3,})\+([0-9]+)\+([0-9]+)").ok()?;
    let mut entries: Vec<(String, i32, i32, bool)> = Vec::new();
    for line in s.lines() {
        let mut parts = line.split_whitespace();
        let name = match parts.next() {
            Some(n) => n,
            None => continue,
        };
        if !line.contains(" connected ") {
            continue;
        }
        if let Some(cap) = geom_re.captures(line) {
            let x: i32 = cap.get(3)?.as_str().parse().ok()?;
            let y: i32 = cap.get(4)?.as_str().parse().ok()?;
            let primary = line.contains(" primary ");
            entries.push((name.to_string(), x, y, primary));
        }
    }
    if entries.is_empty() {
        return None;
    }
    // primary first
    entries.sort_by_key(|e| (!e.3, e.1, e.2));
    let mut args: Vec<String> = vec!["set".into()];
    let mut first = true;
    for (name, x, y, _primary) in entries {
        if first {
            args.push("-Lp".into());
            first = false;
        } else {
            args.push("-L".into());
        }
        args.push("-M".into());
        args.push(name);
        args.push("-x".into());
        args.push(x.to_string());
        args.push("-y".into());
        args.push(y.to_string());
    }
    Some(args)
}

fn args_to_shell(cmd: &str, args: &[String]) -> String {
    let mut s = String::new();
    s.push_str(cmd);
    for a in args {
        s.push(' ');
        s.push_str(&shell_escape(a));
    }
    s
}

fn shell_escape(s: &str) -> String {
    if s.chars()
        .all(|c| c.is_ascii_alphanumeric() || "-_/.:@".contains(c))
    {
        s.to_string()
    } else {
        let escaped = s.replace('\'', "'\\''");
        format!("'{}'", escaped)
    }
}

fn snapshot_dir() -> PathBuf {
    let base = env::var("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| dirs_home_config());
    base.join("monitor-tui")
}

fn dirs_home_config() -> PathBuf {
    let home = env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("."));
    home.join(".config")
}

fn snapshot_save(label: &str, cmdline: &str) -> Result<PathBuf> {
    let dir = snapshot_dir();
    fs::create_dir_all(&dir)?;
    let mut name = label.replace(|c: char| c.is_whitespace(), "_");
    name.retain(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-' || c == '.');
    if name.is_empty() {
        name = format!("snapshot_{}", chrono::Local::now().format("%Y%m%d_%H%M%S"));
    }
    let file = dir.join(format!("{}.sh", name));
    let content = format!("#!/usr/bin/env bash\nset -euo pipefail\n{}\n", cmdline);
    fs::write(&file, content)?;
    let _ = Command::new("chmod").arg("+x").arg(&file).status();
    Ok(file)
}

fn snapshot_pick() -> Result<Option<PathBuf>> {
    let dir = snapshot_dir();
    let mut entries: Vec<PathBuf> = if dir.exists() {
        fs::read_dir(&dir)?
            .filter_map(|e| e.ok().map(|e| e.path()))
            .collect()
    } else {
        vec![]
    };
    entries.sort();
    entries.retain(|p| p.extension().map(|e| e == "sh").unwrap_or(false));
    if entries.is_empty() {
        msgbox("No snapshots saved yet.");
        return Ok(None);
    }
    let opts: Vec<(String, String)> = entries
        .iter()
        .map(|p| {
            let base = p.file_name().unwrap().to_string_lossy().to_string();
            (base.clone(), format!("{}", base))
        })
        .collect();
    if let Some(sel) = menu("Snapshots:", &opts)? {
        return Ok(Some(dir.join(sel)));
    }
    Ok(None)
}

fn main() -> Result<()> {
    if !have("gnome-monitor-config") {
        msgbox("gnome-monitor-config is required (Wayland). Please install it (part of GNOME). Aborting.");
        return Ok(());
    }

    loop {
        let choice = menu(
            "Choose an action:",
            &[
                ("new".into(), "Create & apply a new layout".into()),
                ("apply".into(), "Apply a saved snapshot".into()),
                ("delete".into(), "Delete a saved snapshot".into()),
                ("snapshot".into(), "Save CURRENT layout as snapshot".into()),
                ("quit".into(), "Quit".into()),
            ],
        )?;
        match choice.as_deref() {
            Some("new") => new_layout()?,
            Some("apply") => {
                if let Some(p) = snapshot_pick()? {
                    let _ = Command::new("bash").arg(p).status();
                }
            }
            Some("delete") => {
                if let Some(p) = snapshot_pick()? {
                    let _ = fs::remove_file(&p);
                    msgbox(&format!(
                        "Deleted snapshot: {}",
                        p.file_name().unwrap().to_string_lossy()
                    ));
                }
            }
            Some("snapshot") => match current_layout_args() {
                Some(args) => {
                    let default =
                        format!("current_{}", chrono::Local::now().format("%Y%m%d_%H%M%S"));
                    let label = inputbox("Snapshot label:", &default)?;
                    let cmdline = args_to_shell("gnome-monitor-config", &args);
                    let file = snapshot_save(&label, &cmdline)?;
                    msgbox(&format!(
                        "Saved snapshot of CURRENT layout: {}",
                        file.display()
                    ));
                }
                None => {
                    msgbox("Could not detect current layout (xrandr geometry not available).\nTry applying a layout via this tool first, then snapshot.");
                }
            },
            Some("quit") | None => break,
            _ => {}
        }
    }
    Ok(())
}

fn new_layout() -> Result<()> {
    let conns = discover_connectors();
    let mut cl_args: Vec<(String, String, bool)> = Vec::new();
    for c in &conns {
        cl_args.push((c.clone(), describe_connector(c), false));
    }
    let picked = checklist("Pick one or more connectors to MIRROR as a single logical monitor (these will be your 'big' display):", &cl_args)?;
    if picked.is_empty() {
        msgbox("You must select at least one connector.");
        return Ok(());
    }

    // Summary
    let mut summary = String::new();
    for c in &conns {
        summary.push_str(&format!("{} {}\n", c, describe_connector(c)));
    }
    msgbox(&format!("Detected connectors:\n{}", summary));

    let place = match menu(
        "Where do you want to place the OTHER monitors relative to the mirrored group?",
        &[
            (
                "below".into(),
                "Below (typical laptop-under-desktop)".into(),
            ),
            ("above".into(), "Above".into()),
            ("left".into(), "Left".into()),
            ("right".into(), "Right".into()),
        ],
    )? {
        Some(p) => p.to_string(),
        None => return Ok(()),
    };

    let pick_set: BTreeSet<String> = picked.iter().cloned().collect();
    let mut others: Vec<String> = conns
        .iter()
        .filter(|c| !pick_set.contains(*c))
        .cloned()
        .collect();

    if !others.is_empty() {
        let mut cl2: Vec<(String, String, bool)> = Vec::new();
        for o in &others {
            cl2.push((o.clone(), describe_connector(o), true));
        }
        let picked2 = checklist(&format!("Select which of the remaining connectors to include (they will be placed {} the group):", place), &cl2)?;
        others = picked2;
    }

    // Auto-calculate offsets based on monitor sizes and placement
    let args = build_command_args_auto(&picked, &place, &others);
    let status = Command::new("gnome-monitor-config").args(&args).status()?;
    let cmdline = args_to_shell("gnome-monitor-config", &args);
    if status.success() {
        msgbox(&format!("Applied:\n{}", cmdline));
        if let Some(ans) = menu(
            "Snapshot this working layout?",
            &[
                ("yes".into(), "Save snapshot".into()),
                ("no".into(), "Skip".into()),
            ],
        )? {
            if ans == "yes" {
                let default = format!(
                    "mirrored_group_{}",
                    chrono::Local::now().format("%Y%m%d_%H%M%S")
                );
                let label = inputbox("Snapshot label:", &default)?;
                let file = snapshot_save(&label, &cmdline)?;
                msgbox(&format!("Saved snapshot: {}", file.display()));
            }
        }
    } else {
        msgbox(&format!(
            "Failed to apply the layout.\nCommand was:\n{}",
            cmdline
        ));
    }

    Ok(())
}
