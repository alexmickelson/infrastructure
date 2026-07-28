---
name: firecrawl-api
description: Search the web, retrieve webpage content, and run asynchronous crawls through the self-hosted Firecrawl API at firecrawl.beefalo-newton.ts.net. Use when a task needs web search, a clean Markdown representation of a webpage, or a crawl of a site through this local service.
---

# Firecrawl API

No API key is required.

Search:

```bash
curl -sS -X POST https://firecrawl.beefalo-newton.ts.net/v1/search -H 'Content-Type: application/json' -d '{"query":"your search query","limit":5}'
```

Scrape one page as Markdown:

```bash
curl -sS -X POST https://firecrawl.beefalo-newton.ts.net/v1/scrape -H 'Content-Type: application/json' -d '{"url":"https://example.com","formats":["markdown"]}'
```

Crawl a site:

```bash
curl -sS -X POST https://firecrawl.beefalo-newton.ts.net/v1/crawl -H 'Content-Type: application/json' -d '{"url":"https://example.com","limit":1}'
```

Get crawl progress and results (replace `<job-id>` with the returned ID):

```bash
curl -sS 'https://firecrawl.beefalo-newton.ts.net/v1/crawl/<job-id>'
```
