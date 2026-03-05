(async function () {
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

  function escapeHtml(str) {
    return (str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }

  function langDot(lang) {
    const colors = {
      Go:'#00ADD8', Python:'#3572A5', JavaScript:'#f1e05a', TypeScript:'#2b7489',
      Rust:'#dea584', Java:'#b07219', 'C#':'#178600', Nix:'#7e7eff',
      Shell:'#89e051', HTML:'#e34c26', CSS:'#563d7c', Elixir:'#6e4a7e',
    };
    return colors[lang]
      ? `<span style="width:10px;height:10px;border-radius:50%;background:${colors[lang]};display:inline-block;flex-shrink:0"></span>`
      : '📦';
  }

  async function fetchJson(url) {
    const resp = await fetch(url, { credentials: 'include' });
    if (!resp.ok) throw new Error(resp.status);
    return resp.json();
  }

  async function getLatestCommit(repo) {
    try {
      const commits = await fetchJson(
        `${baseUrl}/api/v1/repos/${encodeURIComponent(repo.full_name)}/commits?limit=1&page=1`
      );
      if (commits && commits.length > 0) return commits[0];
    } catch (_) {}
    return null;
  }

  async function loadRepos() {
    let repos;
    try {
      const resp = await fetch(`${baseUrl}/api/v1/repos/search?sort=updated&order=desc&limit=12`, {
        credentials: 'include',
      });
      if (!resp.ok) {
        const msg = resp.status === 401 || resp.status === 403
          ? `Sign in to see repositories (HTTP ${resp.status})`
          : `API error: HTTP ${resp.status}`;
        grid.innerHTML = `<div class="error-msg">${msg}. <a href="${baseUrl}/explore/repos" style="color:#58a6ff">Browse manually →</a></div>`;
        return;
      }
      const json = await resp.json();
      repos = json.data || json;
    } catch (e) {
      console.error('Gitea landing: repo fetch failed', e);
      grid.innerHTML = `<div class="error-msg">
        Could not load repositories (${e.message}). <a href="${baseUrl}/explore/repos" style="color:#58a6ff">Browse manually →</a>
      </div>`;
      return;
    }

    if (!repos || repos.length === 0) {
      grid.innerHTML = `<div class="error-msg">No public repositories found.</div>`;
      return;
    }

    repos.sort((a, b) => new Date(b.updated) - new Date(a.updated));

    grid.innerHTML = '';
    for (const repo of repos) {
      const card = document.createElement('a');
      card.className = 'repo-card';
      card.href = `${baseUrl}/${escapeHtml(repo.full_name)}`;
      card.dataset.repoName = repo.full_name;
      card.innerHTML = `
        <div class="repo-card-header">
          <span class="repo-icon">${langDot(repo.language)}</span>
          <span class="repo-name">${escapeHtml(repo.name)}</span>
          ${repo.private ? '<span class="repo-private">private</span>' : ''}
        </div>
        <div class="repo-desc">${escapeHtml(repo.description) || '<em style="color:#484f58">No description</em>'}</div>
        <div class="repo-meta">
          ${repo.language ? `<span>${langDot(repo.language)} ${escapeHtml(repo.language)}</span>` : ''}
          <span>⭐ ${repo.stars_count || 0}</span>
          <span>🍴 ${repo.forks_count || 0}</span>
          <span>🕒 ${timeAgo(repo.updated)}</span>
        </div>
        <div class="repo-commit" id="commit-${CSS.escape(repo.full_name)}">
          <span class="commit-dot"></span>
          <span class="commit-msg" style="color:#484f58">loading commit…</span>
        </div>
      `.trim();
      grid.appendChild(card);
    }

    await Promise.all(repos.map(async (repo) => {
      const commit = await getLatestCommit(repo);
      const el = document.getElementById(`commit-${CSS.escape(repo.full_name)}`);
      if (!el) return;
      if (commit) {
        const msg = commit.commit?.message?.split('\n')[0] || '';
        const when = timeAgo(commit.commit?.committer?.date || commit.created);
        el.innerHTML = `
          <span class="commit-dot"></span>
          <span class="commit-msg">${escapeHtml(msg)}</span>
          <span class="commit-time">${when}</span>
        `;
      } else {
        el.innerHTML = `<span class="commit-dot" style="background:#484f58"></span><span class="commit-msg" style="color:#484f58">no commits visible</span>`;
      }
    }));
  }

  loadRepos();
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

    let icon = '⚡';
    const t = title.toLowerCase();
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

    let commitsHtml = '';
    const descDoc = new DOMParser().parseFromString(description, 'text/html');
    const commitEls = descDoc.querySelectorAll('li');
    if (commitEls.length > 0) {
      commitsHtml = '<div class="activity-commits">' +
        Array.from(commitEls).slice(0, 3).map(li => {
          const anchor = li.querySelector('a');
          const sha = anchor ? esc(anchor.textContent.trim().slice(0, 7)) : '';
          const shaHref = anchor ? esc(anchor.getAttribute('href') || '#') : '#';
          const msg = esc(li.textContent.replace(anchor?.textContent || '', '').trim().replace(/^[-–:]\s*/, ''));
          return `<div class="activity-commit-line">
            ${sha ? `<a class="activity-commit-sha" href="${shaHref}">${sha}</a>` : ''}
            <span class="activity-commit-text">${msg}</span>
          </div>`;
        }).join('') +
        (commitEls.length > 3 ? `<div class="activity-commit-line" style="color:#484f58">+${commitEls.length - 3} more</div>` : '') +
        '</div>';
    }

    const el = document.createElement('div');
    el.className = 'activity-item';
    el.innerHTML = `
      <div class="activity-op-icon">${icon}</div>
      <div class="activity-body">
        <div class="activity-headline"><a href="${esc(link)}">${esc(title)}</a></div>
        ${commitsHtml}
      </div>
      <span class="activity-time">${when}</span>
    `;
    feed.appendChild(el);
  }
})();
