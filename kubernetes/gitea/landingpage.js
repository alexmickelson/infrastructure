const baseUrl = window.GITEA_SUB_URL || "";
const httpService = {

  async fetchRss() {
    const resp = await fetch(`${baseUrl}/alex.rss`);
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const text = await resp.text();
    return new DOMParser().parseFromString(text, "application/xml");
  },

  async fetchHeatmap(username = "alex") {
    const resp = await fetch(`${baseUrl}/api/v1/users/${username}/heatmap`);
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    return resp.json(); // [{timestamp: unix_seconds, contributions: number}]
  },
};

const dataDomain = {
  timeAgo(dateStr) {
    const diff = (Date.now() - new Date(dateStr)) / 1000;
    if (diff < 60) return "just now";
    if (diff < 3600) return Math.floor(diff / 60) + "m ago";
    if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
    if (diff < 2592000) return Math.floor(diff / 86400) + "d ago";
    if (diff < 31536000) return Math.floor(diff / 2592000) + "mo ago";
    return Math.floor(diff / 31536000) + "y ago";
  },

  esc(str) {
    return (str || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  },

  safeTitleHtml(rawTitleText) {
    const doc = new DOMParser().parseFromString(rawTitleText, "text/html");
    doc.body
      .querySelectorAll("*:not(a)")
      .forEach((el) => el.replaceWith(el.textContent));
    return doc.body.innerHTML;
  },

  titlePlainText(rawTitleText) {
    const doc = new DOMParser().parseFromString(rawTitleText, "text/html");
    return doc.body.textContent || rawTitleText;
  },

  activityIcon(titleText) {
    const t = titleText.toLowerCase();
    if (t.includes("push") || t.includes("commit")) return "📤";
    if (t.includes("creat") && t.includes("repo")) return "📁";
    if (t.includes("fork")) return "🍴";
    if (t.includes("open") && t.includes("issue")) return "🔴";
    if (t.includes("clos") && t.includes("issue")) return "🟢";
    if (t.includes("pull request") || t.includes("merge")) return "🔀";
    if (t.includes("tag")) return "🏷️";
    if (t.includes("branch")) return "🌿";
    if (t.includes("comment")) return "💬";
    if (t.includes("release")) return "🚀";
    return "⚡";
  },

  parseCommits(descriptionText) {
    const doc = new DOMParser().parseFromString(descriptionText, "text/html");
    return Array.from(doc.querySelectorAll("a")).map((anchor) => {
      const sha = anchor.textContent.trim().slice(0, 7);
      const href = anchor.getAttribute("href") || "#";
      let msg = "";
      let node = anchor.nextSibling;
      while (node) {
        const t = (node.textContent || "").trim();
        if (t) {
          msg = t;
          break;
        }
        node = node.nextSibling;
      }
      return { sha, href, msg };
    });
  },

  parseRepos(xmlDoc) {
    const items = Array.from(xmlDoc.querySelectorAll("channel > item"));
    const seen = new Map();
    for (const item of items) {
      const titleHtml = item.querySelector("title")?.textContent || "";
      const titleDoc = new DOMParser().parseFromString(titleHtml, "text/html");
      const anchors = titleDoc.querySelectorAll("a");
      if (anchors.length < 2) continue;
      const repoAnchor = anchors[anchors.length - 1];
      const repoName = repoAnchor.textContent.trim();
      if (!repoName || seen.has(repoName)) continue;
      seen.set(repoName, {
        repoName,
        repoUrl: repoAnchor.getAttribute("href") || "#",
        shortName: repoName.includes("/")
          ? repoName.split("/").pop()
          : repoName,
        pubDate: item.querySelector("pubDate")?.textContent || "",
        firstCommit:
          dataDomain.parseCommits(
            item.querySelector("description")?.textContent || "",
          )[0] || null,
      });
    }
    return Array.from(seen.values());
  },

  parseAllActivityDates(xmlDoc) {
    const counts = new Map();
    for (const item of Array.from(xmlDoc.querySelectorAll("channel > item"))) {
      const pubDate = item.querySelector("pubDate")?.textContent || "";
      if (!pubDate) continue;
      const d = new Date(pubDate);
      if (isNaN(d)) continue;
      const key = d.toISOString().slice(0, 10);
      counts.set(key, (counts.get(key) || 0) + 1);
    }
    return counts;
  },

  parseActivity(xmlDoc, limit = 20) {
    return Array.from(xmlDoc.querySelectorAll("channel > item"))
      .slice(0, limit)
      .map((item) => {
        const rawTitle = item.querySelector("title")?.textContent || "";
        const titleText = dataDomain.titlePlainText(rawTitle);
        return {
          titleHtmlSafe: dataDomain.safeTitleHtml(rawTitle),
          titleText,
          link: item.querySelector("link")?.textContent || "#",
          pubDate: item.querySelector("pubDate")?.textContent || "",
          icon: dataDomain.activityIcon(titleText),
          commits: dataDomain.parseCommits(
            item.querySelector("description")?.textContent || "",
          ).slice(0, 3),
        };
      });
  },
};

const uiRendering = {
  async renderRepos(xmlDoc) {
    const grid = document.getElementById("repo-grid");
    if (!grid) return;

    const repos = dataDomain.parseRepos(xmlDoc);
    if (repos.length === 0) {
      grid.innerHTML = `<div class="error-msg">No repositories found in feed.</div>`;
      return;
    }

    grid.innerHTML = "";
    for (const {
      shortName,
      repoName,
      repoUrl,
      pubDate,
      firstCommit,
    } of repos) {
      const when = dataDomain.timeAgo(pubDate);
      const commitMsg = firstCommit?.msg || firstCommit?.sha || "";

      const card = document.createElement("a");
      card.className = "repo-card";
      card.href = dataDomain.esc(repoUrl);
      card.innerHTML = `
        <div class="repo-card-header">
          <span class="repo-icon">📦</span>
          <span class="repo-name">${dataDomain.esc(shortName)}</span>
        </div>
        <div class="repo-desc">${dataDomain.esc(repoName)}</div>
        <div class="repo-commit">
          <span class="commit-dot"></span>
          <span class="commit-msg">${dataDomain.esc(commitMsg)}</span>
          <span class="commit-time">${dataDomain.esc(when)}</span>
        </div>
      `.trim();
      grid.appendChild(card);
    }
  },

  async renderActivity(xmlDoc) {
    const feed = document.getElementById("activity-feed");
    if (!feed) return;

    const items = dataDomain.parseActivity(xmlDoc);
    if (items.length === 0) {
      feed.innerHTML = `<div class="error-msg">No public activity yet.</div>`;
      return;
    }

    feed.innerHTML = "";
    for (const { titleHtmlSafe, icon, pubDate, commits } of items) {
      const when = dataDomain.timeAgo(pubDate);

      const commitsHtml =
        commits.length === 0
          ? ""
          : `<div class="activity-commits">` +
            commits
              .map(
                ({ sha, href, msg }) => `
          <div class="activity-commit-line">
            <a class="activity-commit-sha" href="${dataDomain.esc(href)}">${dataDomain.esc(sha)}</a>
            <span class="activity-commit-text">${dataDomain.esc(msg)}</span>
          </div>`,
              )
              .join("") +
            `</div>`;

      const el = document.createElement("div");
      el.className = "activity-item";
      el.innerHTML = `
        <div class="activity-op-icon">${icon}</div>
        <div class="activity-body">
          <div class="activity-headline-row">
            <div class="activity-headline">${titleHtmlSafe}</div>
            <span class="activity-time">${when}</span>
          </div>
          ${commitsHtml}
        </div>
      `;
      feed.appendChild(el);
    }
  },

  async activityMapRender() {
    const container = document.getElementById("activity-heatmap");
    if (!container) return;

    let heatmapData;
    try {
      heatmapData = await httpService.fetchHeatmap();
    } catch (e) {
      container.innerHTML = `<div class="error-msg">Could not load heatmap (${e.message})</div>`;
      return;
    }

    // Build counts map from API data
    const counts = new Map();
    for (const { timestamp, contributions } of heatmapData) {
      const d = new Date(timestamp * 1000);
      const key = d.toISOString().slice(0, 10);
      counts.set(key, (counts.get(key) || 0) + (contributions || 1));
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Align start to Sunday 52 weeks ago
    const startDate = new Date(today);
    startDate.setDate(startDate.getDate() - 52 * 7);
    startDate.setDate(startDate.getDate() - startDate.getDay());

    const cellSize = 11;
    const gap = 2;
    const step = cellSize + gap;
    const cols = 53;
    const rows = 7;
    const padLeft = 28;
    const padTop = 20;
    const svgW = padLeft + cols * step;
    const svgH = padTop + rows * step;

    const LEVELS = ["#2d333b", "#0e4429", "#006d32", "#26a641", "#39d353"];
    const countToLevel = (n) =>
      n === 0 ? 0 : n === 1 ? 1 : n <= 3 ? 2 : n <= 6 ? 3 : 4;

    // Collect month labels (one per column where the month changes)
    const monthLabels = new Map();
    let lastMonth = -1;
    for (let col = 0; col < cols; col++) {
      const d = new Date(startDate);
      d.setDate(d.getDate() + col * 7);
      if (d.getMonth() !== lastMonth) {
        lastMonth = d.getMonth();
        monthLabels.set(col, d.toLocaleString("default", { month: "short" }));
      }
    }

    const ns = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(ns, "svg");
    svg.setAttribute("width", svgW);
    svg.setAttribute("height", svgH);
    svg.setAttribute("class", "heatmap-svg");
    svg.setAttribute("aria-label", "Activity heatmap");

    // Month labels
    for (const [col, name] of monthLabels) {
      const t = document.createElementNS(ns, "text");
      t.setAttribute("x", padLeft + col * step);
      t.setAttribute("y", 12);
      t.setAttribute("class", "heatmap-month");
      t.textContent = name;
      svg.appendChild(t);
    }

    // Day-of-week labels (Sun / Tue / Thu / Sat)
    ["Sun", "", "Tue", "", "Thu", "", "Sat"].forEach((label, i) => {
      if (!label) return;
      const t = document.createElementNS(ns, "text");
      t.setAttribute("x", 0);
      t.setAttribute("y", padTop + i * step + cellSize - 2);
      t.setAttribute("class", "heatmap-day");
      t.textContent = label;
      svg.appendChild(t);
    });

    // Day cells
    for (let col = 0; col < cols; col++) {
      for (let row = 0; row < rows; row++) {
        const d = new Date(startDate);
        d.setDate(d.getDate() + col * 7 + row);
        if (d > today) continue;

        const key = d.toISOString().slice(0, 10);
        const count = counts.get(key) || 0;

        const rect = document.createElementNS(ns, "rect");
        rect.setAttribute("x", padLeft + col * step);
        rect.setAttribute("y", padTop + row * step);
        rect.setAttribute("width", cellSize);
        rect.setAttribute("height", cellSize);
        rect.setAttribute("rx", 2);
        rect.setAttribute("fill", LEVELS[countToLevel(count)]);
        rect.setAttribute("data-date", key);
        rect.setAttribute("data-count", count);

        const title = document.createElementNS(ns, "title");
        title.textContent = count > 0
          ? `${count} activit${count === 1 ? "y" : "ies"} on ${key}`
          : `No activity on ${key}`;
        rect.appendChild(title);
        svg.appendChild(rect);
      }
    }

    // Legend
    const legendY = svgH + 6;
    const legendG = document.createElementNS(ns, "g");
    const legendLabel = document.createElementNS(ns, "text");
    legendLabel.setAttribute("x", padLeft);
    legendLabel.setAttribute("y", legendY + cellSize - 2);
    legendLabel.setAttribute("class", "heatmap-day");
    legendLabel.textContent = "Less";
    legendG.appendChild(legendLabel);
    LEVELS.forEach((color, i) => {
      const r = document.createElementNS(ns, "rect");
      r.setAttribute("x", padLeft + 32 + i * step);
      r.setAttribute("y", legendY);
      r.setAttribute("width", cellSize);
      r.setAttribute("height", cellSize);
      r.setAttribute("rx", 2);
      r.setAttribute("fill", color);
      legendG.appendChild(r);
    });
    const moreLabel = document.createElementNS(ns, "text");
    moreLabel.setAttribute("x", padLeft + 32 + LEVELS.length * step + 4);
    moreLabel.setAttribute("y", legendY + cellSize - 2);
    moreLabel.setAttribute("class", "heatmap-day");
    moreLabel.textContent = "More";
    legendG.appendChild(moreLabel);
    svg.setAttribute("height", svgH + cellSize + 12);
    svg.appendChild(legendG);

    container.innerHTML = "";
    container.appendChild(svg);
  },

  async render() {
    const baseUrl = httpService.baseUrl;

    try {
      const xmlDoc = await httpService.fetchRss();
      await Promise.all([
        uiRendering.renderRepos(xmlDoc),
        uiRendering.renderActivity(xmlDoc),
        uiRendering.activityMapRender(),
      ]);
    } catch (e) {
      console.error("Gitea landing: RSS fetch failed", e);
      const grid = document.getElementById("repo-grid");
      const feed = document.getElementById("activity-feed");
      if (grid)
        grid.innerHTML = `<div class="error-msg">Could not load feed (${e.message}). <a href="${baseUrl}/explore/repos" style="color:#58a6ff">Browse manually →</a></div>`;
      if (feed)
        feed.innerHTML = `<div class="error-msg">Could not load activity (${e.message})</div>`;
      return;
    }
  },
};

document.addEventListener("DOMContentLoaded", () => uiRendering.render());
