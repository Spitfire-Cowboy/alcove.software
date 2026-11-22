# alcove.software

Private build repository for the public Alcove world.

This repo owns:
- Static web content for `alcove.software`
- Search crawler/indexing controls (`robots.txt`, `sitemap.xml`, `llms.txt`)
- Public handoff docs for operators, developers, and AI/tooling consumers

## Local Usage

Build/validate site artifacts:

```bash
npm ci
npm run build:css
./scripts/validate_site.sh
```

Tailwind scans the static HTML and writes `site/assets/tailwind.css`. The
generated file is committed so a checkout can still serve `site/` directly.
Page-specific artwork remains in the existing CSS files; new shared layout and
navigation should use Tailwind utilities.

## Deployment

GitHub Actions deploys `site/` to GitHub Pages from `main`.
Public docs landing page is served at `https://alcove.software/docs/`.

Search indexing operator runbook:
- `docs/ops/SEARCH_INDEXING_ONBOARDING.md`

## Scope

This repo is intentionally separate from the core `alcove` engine codebase.
