# Repo Mirroring: Spitfire-Cowboy -> Pro777

This repository runs scheduled one-way mirroring for:

- `Spitfire-Cowboy/alcove` -> `Pro777/alcove`
- `Spitfire-Cowboy/alcove-private` -> `Pro777/alcove-private`
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

- Mirrors all branches and tags.
- Uses prune mode so deleted source branches/tags are deleted in destination.
- Does not mirror Issues/PR metadata/settings/secrets.
- Hidden GitHub refs (`refs/pull/*`) are intentionally excluded.

## Monitoring

- Drift check workflow: `.github/workflows/mirror-parity-check.yml`
- Weekly status workflow: `.github/workflows/weekly-mirror-health.yml`
- Weekly status is appended as comments to issue #9.

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
