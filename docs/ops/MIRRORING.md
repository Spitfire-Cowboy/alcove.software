# Repo Mirroring: Spitfire-Cowboy -> Pro777

This repository runs scheduled one-way mirroring for:

- `Spitfire-Cowboy/alcove` -> `Pro777/alcove`
- `Spitfire-Cowboy/alcove-private` -> `Pro777/alcove-private` (PR-based sync into `develop`)
- `Spitfire-Cowboy/alcove-demo` -> `Pro777/alcove-demo`

Workflow: `.github/workflows/mirror-pro777-repos.yml`
Script: `scripts/ops/mirror_repo_pair.sh`

## Required Secrets

- `PRO777_MIRROR_PAT`
  - Fine-grained PAT recommended
  - Scope: read access + repo settings management for destination repositories in `Pro777`
  - Used by parity governance checks and destination automation APIs

- `PRO777_MIRROR_SSH_KEY` (optional)
  - Private SSH key for a GitHub user with write access to destination repositories in `Pro777`
  - Preferred for destination push auth

- `SPITFIRE_MIRROR_SSH_KEY`
  - Backward-compatible fallback if `PRO777_MIRROR_SSH_KEY` is not set
  - Must also have write access to destination repositories in `Pro777`

- `SPITFIRE_MIRROR_PAT`
  - Fine-grained PAT recommended
  - Scope: read access to source repositories in `Spitfire-Cowboy`, plus settings access to `Spitfire-Cowboy/alcove.software` for governance jobs
  - Used for source fetch in mirror/parity/report workflows and secret-age governance checks

## Behavior

- Direct mirror pairs (`alcove`, `alcove-demo`):
  - Mirror all branches and tags.
  - Use prune mode so deleted source branches/tags are deleted in destination.
  - Default mode is safety-first:
    - Fast-forward-only branch updates
    - Tag rewrites blocked
    - Large prune deletions blocked when count exceeds `MAX_PRUNE_DELETIONS` (default `5`)
  - Destructive reconciliation requires explicit opt-in (`ALLOW_FORCE_MIRROR=1`) via manual workflow dispatch.
- PR-based pair (`alcove-private`):
  - Mirror the canonical `develop` tip onto automation branch `mirror/spitfire-alcove-private-develop`.
  - Open or update a destination PR from that sync branch into `Pro777/alcove-private:develop`.
  - Do **not** prune destination-only branches/tags in this mode; the destination repo may carry review-only or historical branches that should not be deleted automatically.
- Does not mirror Issues/PR metadata/settings/secrets.
- Hidden GitHub refs (`refs/pull/*`) are intentionally excluded.

## Manual Dispatch

- Use scheduled runs for normal operation.
- Use manual dispatch only when needed:
  - `allow_force_mirror=false` (default): safe mode
  - `allow_force_mirror=true`: allows non-fast-forward updates and large prune deletes
  - `max_prune_deletions`: safe-mode deletion guardrail override for that run
- `allow_force_mirror` and `max_prune_deletions` apply only to direct mirror pairs; the PR-based `alcove-private` sync ignores prune/force options and refreshes its promotion PR instead.

## Monitoring

- Drift check workflow: `.github/workflows/mirror-parity-check.yml`
- Weekly status workflow: `.github/workflows/weekly-mirror-health.yml`
- Weekly status is appended as comments to issue #9.
- Rolling incident issues:
  - Parity drift: #116
  - Mirror blocked: #143
- Alert dedupe: workflows post at most one marker comment per workflow run to each rolling incident issue.
- Closure condition: rolling incidents auto-close only after 3 consecutive healthy workflow runs.
- PR-based parity for `alcove-private` is considered healthy when either:
  - `Pro777/alcove-private:develop` already matches `Spitfire-Cowboy/alcove-private:develop`, or
  - an open PR from `mirror/spitfire-alcove-private-develop` carries the current source SHA.

## Operational Rules

- `Spitfire-Cowboy/*` repos are canonical.
- `Pro777/*` repos are compatibility mirrors during transition.
- Destination private repos stay private and non-forkable.
- `Pro777/alcove` mirrors public visibility from `Spitfire-Cowboy/alcove`.
- During transition, all production writes happen to `Spitfire-Cowboy/*`.

## Final Cutover Steps

- Freeze destination writes during cutover window.
- Run manual mirror dispatch and verify default branch SHA parity.
- Remove mirror workflows when `Pro777/*` copies are no longer needed.
- Archive or lock destination repos after confidence window.
