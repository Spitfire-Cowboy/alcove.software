# API (Read-Only) Overview

This public site documents the intended read-only API surface for `api.alcove.software`.

Current status:
- Spec track: `docs/API_READONLY_SPEC.md` (planned in issue `#4`)
- Production endpoint: not yet launched from this repo

Design constraints:

- Read-only query endpoints only (no write/index mutation from public API).
- Cache-first edge behavior for predictable public load.
- Abuse controls (rate limiting, logging policy, bot controls) defined before launch.

See issue `Spitfire-Cowboy/alcove.software#4` for implementation planning and acceptance criteria.

