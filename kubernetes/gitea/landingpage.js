(async function loadRepos() {
  const grid = document.getElementById('repo-grid');
  if (!grid) return;

  const baseUrl = window.GITEA_SUB_URL || '';

  function timeAgo(dateStr) {
    const diff = (Date.now() - new Date(dateStr)) / 1000;
    if (diff < 60) return 'just now';
    if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
    if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
    if (diff < 2592000) return Math.floor(diff / 86400) + 'd ago';
    if (diff < 31536000) return Math.floor(diff / 2592000) + 'mo ago';
    return Math.floor(diff / 31536000) + 'y ago';
  }

  function esc(str) {
    return (str || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  let doc;
  try {
    const resp = await fetch(`${baseUrl}/alex.rss`);
    if (!resp.ok) {
      grid.innerHTML = `<div class="error-msg">Could not load feed (HTTP ${resp.status}). <a href="${baseUrl}/explore/repos" style="color:#58a6ff">Browse manually →</a></div>`;
      return;
    }
    const text = await resp.text();
    doc = new DOMParser().parseFromString(text, 'application/xml');
  } catch (e) {
    console.error('Gitea landing: RSS fetch failed', e);
    grid.innerHTML = `<div class="error-msg">Could not load repositories. <a href="${baseUrl}/explore/repos" style="color:#58a6ff">Browse manually →</a></div>`;
    return;
  }

  const items = Array.from(doc.querySelectorAll('channel > item'));
  if (items.length === 0) {
    grid.innerHTML = `<div class="error-msg">No activity found.</div>`;
    return;
  }

  // Deduplicate: one card per repo (most recent entry wins)
  const seen = new Map();
  for (const item of items) {
    const titleHtml = item.querySelector('title')?.textContent || '';
    const titleDoc = new DOMParser().parseFromString(titleHtml, 'text/html');
    const anchors = titleDoc.querySelectorAll('a');
    if (anchors.length < 2) continue;
    // last anchor in the title is the repo link
    const repoAnchor = anchors[anchors.length - 1];
    const repoName = repoAnchor.textContent.trim();
    if (!repoName || seen.has(repoName)) continue;
    seen.set(repoName, { repoName, repoUrl: repoAnchor.getAttribute('href') || '#', item });
  }

  if (seen.size === 0) {
    grid.innerHTML = `<div class="error-msg">No repositories found in feed.</div>`;
    return;
  }

  grid.innerHTML = '';
  for (const { repoName, repoUrl, item } of seen.values()) {
    const pubDate = item.querySelector('pubDate')?.textContent || '';
    const description = item.querySelector('description')?.textContent || '';
    const when = pubDate ? timeAgo(pubDate) : '';

    // Parse first commit from description: <a href="commit-url">sha</a>\ncommit message
    const descDoc = new DOMParser().parseFromString(description, 'text/html');
    const firstAnchor = descDoc.querySelector('a');
    let commitMsg = '';
    let commitUrl = '#';
    if (firstAnchor) {
      commitUrl = firstAnchor.getAttribute('href') || '#';
      let node = firstAnchor.nextSibling;
      while (node) {
        const t = (node.textContent || '').trim();
        if (t) { commitMsg = t; break; }
        node = node.nextSibling;
      }
      if (!commitMsg) commitMsg = firstAnchor.textContent.trim().slice(0, 7);
    }

    const shortName = repoName.includes('/') ? repoName.split('/').pop() : repoName;

    const card = document.createElement('a');
    card.className = 'repo-card';
    card.href = esc(repoUrl);
    card.innerHTML = `
      <div class="repo-card-header">
        <span class="repo-name">${esc(shortName)}</span>
      </div>
      <div class="repo-desc" style="color:#8b949e;font-size:0.85em">${esc(repoName)}</div>
      <div class="repo-commit">
        <span class="commit-dot"></span>
        <span class="commit-msg">${esc(commitMsg)}</span>
        <span class="commit-time">${esc(when)}</span>
      </div>
    `.trim();
    grid.appendChild(card);
  }
})();

(async function loadActivity() {
  const feed = document.getElementById('activity-feed');
  if (!feed) return;
  const baseUrl = window.GITEA_SUB_URL || '';

  function timeAgo(dateStr) {
    const diff = (Date.now() - new Date(dateStr)) / 1000;
    if (diff < 60) return 'just now';
    if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
    if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
    if (diff < 2592000) return Math.floor(diff / 86400) + 'd ago';
    if (diff < 31536000) return Math.floor(diff / 2592000) + 'mo ago';
    return Math.floor(diff / 31536000) + 'y ago';
  }
  function esc(str) {
    return (str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }

  let doc;
  try {
    const resp = await fetch(`${baseUrl}/alex.rss`);
    if (!resp.ok) {
      feed.innerHTML = `<div style="padding:24px;text-align:center;color:#8b949e">Activity unavailable (HTTP ${resp.status})</div>`;
      return;
    }
    const text = await resp.text();
    doc = new DOMParser().parseFromString(text, 'application/xml');
  } catch (e) {
    console.error('activity rss error', e);
    feed.innerHTML = `<div style="padding:24px;text-align:center;color:#8b949e">Could not load activity</div>`;
    return;
  }

  const items = Array.from(doc.querySelectorAll('channel > item')).slice(0, 20);
  if (items.length === 0) {
    feed.innerHTML = `<div style="padding:24px;text-align:center;color:#8b949e">No public activity yet.</div>`;
    return;
  }

  feed.innerHTML = '';
  for (const item of items) {
    const title = item.querySelector('title')?.textContent || '';
    const link  = item.querySelector('link')?.textContent || '#';
    const pubDate = item.querySelector('pubDate')?.textContent || '';
    const description = item.querySelector('description')?.textContent || '';
    const when = pubDate ? timeAgo(pubDate) : '';

    // Strip HTML from title for plain text display
    const titleDoc = new DOMParser().parseFromString(title, 'text/html');
    const titleText = titleDoc.body.textContent || title;

    let icon = '⚡';
    const t = titleText.toLowerCase();
    if (t.includes('push') || t.includes('commit')) icon = '📤';
    else if (t.includes('creat') && t.includes('repo')) icon = '📁';
    else if (t.includes('fork')) icon = '🍴';
    else if (t.includes('open') && t.includes('issue')) icon = '🔴';
    else if (t.includes('clos') && t.includes('issue')) icon = '🟢';
    else if (t.includes('pull request') || t.includes('merge')) icon = '🔀';
    else if (t.includes('tag')) icon = '🏷️';
    else if (t.includes('branch')) icon = '🌿';
    else if (t.includes('comment')) icon = '💬';
    else if (t.includes('release')) icon = '🚀';

    // Parse commits from description: <a href="commit-url">sha</a>\ncommit message\n\n...
    let commitsHtml = '';
    const descDoc = new DOMParser().parseFromString(description, 'text/html');
    const commitAnchors = Array.from(descDoc.querySelectorAll('a')).slice(0, 3);
    if (commitAnchors.length > 0) {
      const lines = commitAnchors.map(anchor => {
        const sha = esc(anchor.textContent.trim().slice(0, 7));
        const shaHref = esc(anchor.getAttribute('href') || '#');
        let msg = '';
        let node = anchor.nextSibling;
        while (node) {
          const t = (node.textContent || '').trim();
          if (t) { msg = esc(t); break; }
          node = node.nextSibling;
        }
        return `<div class="activity-commit-line">
          <a class="activity-commit-sha" href="${shaHref}">${sha}</a>
          <span class="activity-commit-text">${msg}</span>
        </div>`;
      }).join('');
      commitsHtml = `<div class="activity-commits">${lines}</div>`;
    }

    const el = document.createElement('div');
    el.className = 'activity-item';
    el.innerHTML = `
      <div class="activity-op-icon">${icon}</div>
      <div class="activity-body">
        <div class="activity-headline"><a href="${esc(link)}">${esc(titleText)}</a></div>
        ${commitsHtml}
      </div>
      <span class="activity-time">${when}</span>
    `;
    feed.appendChild(el);
  }
})();
