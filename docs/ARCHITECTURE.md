# Alcove Software Architecture

## Goal

Publish a clean, indexable public surface for the Alcove ecosystem while keeping core engine development separate.

## Domains

- `alcove.software`: public site and documentation
- `docs.alcove.software`: optional docs split (future)
- `api.alcove.software`: optional read-only API gateway (future)

## Current Build Surface

- `site/index.html`: primary landing page
- `site/docs/index.html`: public docs landing page
- `site/robots.txt`: crawler policy
- `site/sitemap.xml`: public URL inventory
- `site/llms.txt`: machine-readable project summary

## Future Build Surface

- API docs and query playground for read-only public indexes
- Federation directory for discoverable Alcove nodes
- Search schema metadata for external integrations
