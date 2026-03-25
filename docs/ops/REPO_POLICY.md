# Repository Policy Automation

This policy automation keeps migration target repositories in compliant state:

- `Spitfire-Cowboy/alcove`
- `Spitfire-Cowboy/alcove-private`
- `Spitfire-Cowboy/alcove-demo`

Workflow: `.github/workflows/enforce-repo-policy.yml`
Script: `scripts/ops/enforce_spitfire_repo_policy.sh`
API retry wrapper: `scripts/ops/gh_api_retry.sh`

## Enforced Rules

- `alcove` stays public.
- `alcove-private` and `alcove-demo` stay private.
- Private repository forking remains disabled.
- Default branches are pinned:
  - `alcove`: `main`
  - `alcove-private`: `develop`
  - `alcove-demo`: `main`

## Required Secret

- `SPITFIRE_MIRROR_PAT`
  - Must have admin-level repo settings access for destination repos.

## Failure Handling

If enforcement fails, workflow opens an issue in `Spitfire-Cowboy/alcove.software`.
