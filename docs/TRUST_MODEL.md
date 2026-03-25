# Trust Model

Alcove is local-first retrieval infrastructure.

## Core guarantees

- Retrieval-first behavior: return indexed source passages, not generated answers.
- Operator-controlled data: indexing happens on operator-selected corpora.
- Optional AI: semantic embedding is opt-in, not mandatory.
- No mandatory cloud control plane for core search flow.

## Public web posture

- `robots.txt`, `sitemap.xml`, and `llms.txt` are explicitly published.
- Public docs describe boundaries and intended usage.
- Canonical codebase points to `Spitfire-Cowboy/alcove`.

## Out of scope for alcove.software

- Hosting private user indexes.
- Multi-tenant auth/authorization runtime.
- Proprietary telemetry pipelines over operator content.

