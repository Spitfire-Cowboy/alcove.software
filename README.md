# alcove.software

Private build repository for the public Alcove world.

This repo owns:
- Static web content for `alcove.software`
- Search crawler/indexing controls (`robots.txt`, `sitemap.xml`, `llms.txt`)
- Public handoff docs for operators, developers, and AI/tooling consumers

## Local Usage

Build/validate site artifacts:

```bash
./scripts/validate_site.sh
```

Artifacts are served directly from `site/`.

## Deployment

GitHub Actions deploys `site/` to GitHub Pages from `main`.

Search indexing operator runbook:
- `docs/ops/SEARCH_INDEXING_ONBOARDING.md`

## Scope

This repo is intentionally separate from the core `alcove` engine codebase.
