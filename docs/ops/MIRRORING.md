# Repo Mirroring: Pro777 -> Spitfire-Cowboy

This repository runs scheduled one-way mirroring for:

- `Pro777/alcove-private` -> `Spitfire-Cowboy/alcove-private`
- `Pro777/alcove-demo` -> `Spitfire-Cowboy/alcove-demo`

Workflow: `.github/workflows/mirror-pro777-repos.yml`
Script: `scripts/ops/mirror_repo_pair.sh`

## Required Secrets

- `PRO777_MIRROR_PAT`
  - Fine-grained PAT recommended
  - Scope: read access to source repositories in `Pro777`

- `SPITFIRE_MIRROR_PAT`
  - Fine-grained PAT recommended
  - Scope: contents write + repo settings management on destination repositories in `Spitfire-Cowboy`

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

- Source repos remain canonical until final cutover.
- Destination repos stay private and non-forkable.
- During transition, all production writes happen to source repos only.

## Final Cutover Steps

- Freeze source writes during cutover window.
- Run manual mirror dispatch and verify default branch SHA parity.
- Flip canonical remotes/documentation to `Spitfire-Cowboy/*`.
- Archive or lock source repos after confidence window.
