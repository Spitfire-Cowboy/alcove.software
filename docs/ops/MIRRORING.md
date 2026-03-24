# Repo Mirroring: Pro777 -> Spitfire-Cowboy

This repository runs scheduled one-way mirroring for:

- `Pro777/alcove-private` -> `Spitfire-Cowboy/alcove-private`
- `Pro777/alcove-demo` -> `Spitfire-Cowboy/alcove-demo`

Workflow: `.github/workflows/mirror-pro777-repos.yml`
Script: `scripts/ops/mirror_repo_pair.sh`

## Required Secret

- `PRO777_MIRROR_PAT`
  - Fine-grained PAT recommended
  - Scope: read-only access to source repositories in `Pro777`

## Behavior

- Mirrors all branches and tags.
- Uses prune mode so deleted source branches/tags are deleted in destination.
- Does not mirror Issues/PR metadata/settings/secrets.
- Hidden GitHub refs (`refs/pull/*`) are intentionally excluded.

## Operational Rules

- Source repos remain canonical until final cutover.
- Destination repos stay private and non-forkable.
- During transition, all production writes happen to source repos only.

## Final Cutover Steps

- Freeze source writes during cutover window.
- Run manual mirror dispatch and verify default branch SHA parity.
- Flip canonical remotes/documentation to `Spitfire-Cowboy/*`.
- Archive or lock source repos after confidence window.
