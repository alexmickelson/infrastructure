const httpService = {
  baseUrl: window.GITEA_SUB_URL || '',

  async fetchRss() {
    const resp = await fetch(`${this.baseUrl}/alex.rss`);
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const text = await resp.text();
    return new DOMParser().parseFromString(text, 'application/xml');
  },
};

const dataDomain = {
  timeAgo(dateStr) {
    const diff = (Date.now() - new Date(dateStr)) / 1000;
    if (diff < 60) return 'just now';
    if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
    if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
    if (diff < 2592000) return Math.floor(diff / 86400) + 'd ago';
    if (diff < 31536000) return Math.floor(diff / 2592000) + 'mo ago';
    return Math.floor(diff / 31536000) + 'y ago';
  },

  esc(str) {
    return (str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  },

  safeTitleHtml(rawTitleText) {
    const doc = new DOMParser().parseFromString(rawTitleText, 'text/html');
    doc.body.querySelectorAll('*:not(a)').forEach(el => el.replaceWith(el.textContent));
    return doc.body.innerHTML;
  },

  titlePlainText(rawTitleText) {
    const doc = new DOMParser().parseFromString(rawTitleText, 'text/html');
    return doc.body.textContent || rawTitleText;
  },

  activityIcon(titleText) {
    const t = titleText.toLowerCase();
    if (t.includes('push') || t.includes('commit')) return '📤';
    if (t.includes('creat') && t.includes('repo')) return '📁';
    if (t.includes('fork')) return '🍴';
    if (t.includes('open') && t.includes('issue')) return '🔴';
    if (t.includes('clos') && t.includes('issue')) return '🟢';
    if (t.includes('pull request') || t.includes('merge')) return '🔀';
    if (t.includes('tag')) return '🏷️';
    if (t.includes('branch')) return '🌿';
    if (t.includes('comment')) return '💬';
    if (t.includes('release')) return '🚀';
    return '⚡';
  },

  parseCommits(descriptionText) {
    const doc = new DOMParser().parseFromString(descriptionText, 'text/html');
    return Array.from(doc.querySelectorAll('a')).map(anchor => {
      const sha = anchor.textContent.trim().slice(0, 7);
      const href = anchor.getAttribute('href') || '#';
      let msg = '';
      let node = anchor.nextSibling;
      while (node) {
        const t = (node.textContent || '').trim();
        if (t) { msg = t; break; }
        node = node.nextSibling;
      }
      return { sha, href, msg };
    });
  },

  parseRepos(xmlDoc) {
    const items = Array.from(xmlDoc.querySelectorAll('channel > item'));
    const seen = new Map();
    for (const item of items) {
      const titleHtml = item.querySelector('title')?.textContent || '';
      const titleDoc = new DOMParser().parseFromString(titleHtml, 'text/html');
      const anchors = titleDoc.querySelectorAll('a');
      if (anchors.length < 2) continue;
      const repoAnchor = anchors[anchors.length - 1];
      const repoName = repoAnchor.textContent.trim();
      if (!repoName || seen.has(repoName)) continue;
      seen.set(repoName, {
        repoName,
        repoUrl: repoAnchor.getAttribute('href') || '#',
        shortName: repoName.includes('/') ? repoName.split('/').pop() : repoName,
        pubDate: item.querySelector('pubDate')?.textContent || '',
        firstCommit: this.parseCommits(item.querySelector('description')?.textContent || '')[0] || null,
      });
    }
    return Array.from(seen.values());
  },

  parseActivity(xmlDoc, limit = 20) {
    return Array.from(xmlDoc.querySelectorAll('channel > item'))
      .slice(0, limit)
      .map(item => {
        const rawTitle = item.querySelector('title')?.textContent || '';
        const titleText = this.titlePlainText(rawTitle);
        return {
          titleHtmlSafe: this.safeTitleHtml(rawTitle),
          titleText,
          link: item.querySelector('link')?.textContent || '#',
          pubDate: item.querySelector('pubDate')?.textContent || '',
          icon: this.activityIcon(titleText),
          commits: this.parseCommits(item.querySelector('description')?.textContent || '').slice(0, 3),
        };
      });
  },
};

const uiRendering = {
  async renderRepos(xmlDoc) {
    const grid = document.getElementById('repo-grid');
    if (!grid) return;


    const repos = dataDomain.parseRepos(xmlDoc);
    if (repos.length === 0) {
      grid.innerHTML = `<div class="error-msg">No repositories found in feed.</div>`;
      return;
    }

    grid.innerHTML = '';
    for (const { shortName, repoName, repoUrl, pubDate, firstCommit } of repos) {
      const when = dataDomain.timeAgo(pubDate);
      const commitMsg = firstCommit?.msg || firstCommit?.sha || '';

      const card = document.createElement('a');
      card.className = 'repo-card';
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
    const feed = document.getElementById('activity-feed');
    if (!feed) return;

    const items = dataDomain.parseActivity(xmlDoc);
    if (items.length === 0) {
      feed.innerHTML = `<div class="error-msg">No public activity yet.</div>`;
      return;
    }

    feed.innerHTML = '';
    for (const { titleHtmlSafe, icon, pubDate, commits } of items) {
      const when = dataDomain.timeAgo(pubDate);

      const commitsHtml = commits.length === 0 ? '' :
        `<div class="activity-commits">` +
        commits.map(({ sha, href, msg }) => `
          <div class="activity-commit-line">
            <a class="activity-commit-sha" href="${dataDomain.esc(href)}">${dataDomain.esc(sha)}</a>
            <span class="activity-commit-text">${dataDomain.esc(msg)}</span>
          </div>`).join('') +
        `</div>`;

      const el = document.createElement('div');
      el.className = 'activity-item';
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

  async render() {
    const baseUrl = httpService.baseUrl;

    let xmlDoc;
    try {
      xmlDoc = await httpService.fetchRss();
    } catch (e) {
      console.error('Gitea landing: RSS fetch failed', e);
      const grid = document.getElementById('repo-grid');
      const feed = document.getElementById('activity-feed');
      if (grid) grid.innerHTML = `<div class="error-msg">Could not load feed (${e.message}). <a href="${baseUrl}/explore/repos" style="color:#58a6ff">Browse manually →</a></div>`;
      if (feed) feed.innerHTML = `<div class="error-msg">Could not load activity (${e.message})</div>`;
      return;
    }

    await Promise.all([
      this.renderRepos(xmlDoc),
      this.renderActivity(xmlDoc),
    ]);
  },
};

document.addEventListener('DOMContentLoaded', () => uiRendering.render());
