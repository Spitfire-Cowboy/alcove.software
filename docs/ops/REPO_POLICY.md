# Repository Policy Automation

This policy automation keeps migration target repositories in compliant state:

- `Spitfire-Cowboy/alcove-private`
- `Spitfire-Cowboy/alcove-demo`

Workflow: `.github/workflows/enforce-repo-policy.yml`
Script: `scripts/ops/enforce_spitfire_repo_policy.sh`

## Enforced Rules

- Repositories are private.
- Private repository forking remains disabled.
- Default branches are pinned:
  - `alcove-private`: `develop`
  - `alcove-demo`: `main`

## Required Secret

- `SPITFIRE_MIRROR_PAT`
  - Must have admin-level repo settings access for destination repos.

## Failure Handling

If enforcement fails, workflow opens an issue in `Spitfire-Cowboy/alcove.software`.
