# Search Indexing Onboarding (Google + Bing)

Use this runbook to submit and verify `alcove.software` for public indexing.

## Prerequisites

- `site/robots.txt`, `site/sitemap.xml`, `site/llms.txt`, and `site/index.html` are deployed from `main`.
- DNS for `alcove.software` resolves to the active Pages/Cloudflare setup.
- `https://alcove.software/` returns HTTP 200.

## 1) Google Search Console

1. Add property in Search Console:
   - Prefer **Domain property**: `alcove.software`
2. Verify ownership:
   - DNS TXT record in Cloudflare.
3. Submit sitemap:
   - `https://alcove.software/sitemap.xml`
4. Request indexing for:
   - `https://alcove.software/`
   - `https://alcove.software/llms.txt`

## 2) Bing Webmaster Tools

1. Add site in Bing Webmaster Tools:
   - `https://alcove.software/`
2. Verify ownership:
   - DNS TXT record, XML file, or meta tag (DNS preferred).
3. Submit sitemap:
   - `https://alcove.software/sitemap.xml`
4. Request crawl/indexing of root URL.

## 3) Technical Validation

Run local validation before each deploy:

```bash
./scripts/validate_site.sh
```

Validation includes:
- `robots.txt` policy and sitemap declaration
- Googlebot/Bingbot crawl stanzas
- `sitemap.xml` root + llms entries
- canonical codebase link in `llms.txt`
- canonical and robots meta tags in `index.html`

## 4) Post-Submit Monitoring

- Check index coverage weekly in Google/Bing dashboards.
- Watch for crawl errors (4xx/5xx, robots blocked, canonical mismatch).
- Re-submit sitemap after major structural changes.

## 5) Rollback

If indexing artifacts regress:

1. Revert broken changes on `main`.
2. Redeploy Pages.
3. Revalidate:
   - `./scripts/validate_site.sh`
4. Re-submit sitemap in both consoles.

