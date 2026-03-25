# Workflow Migration Plan (Self-Hosted + Rate-Limit Control)

Tracks issue goals:
- `Spitfire-Cowboy/alcove.software#8`
- `Spitfire-Cowboy/alcove.software#9`

## Objectives

- Reduce GitHub-hosted minutes on heavy workflows.
- Reduce queue pressure and duplicate runs.
- Keep required checks stable and rollback-safe.
- Prefer GitHub REST APIs over GraphQL-heavy automation.

## Baseline Measurement

Collect workflow runtime inventory for target repos:

```bash
ORG=Spitfire-Cowboy REPOS="alcove-private alcove-demo" DAYS=14 ./scripts/ops/workflow_runtime_inventory.sh
```

Post the markdown output to tracking issue `#9` weekly.

## Routing Policy

- Heavy scheduled ops jobs:
  - mirror/parity/weekly-health/policy/secret checks
  - Route with `ALCOVE_RUNNER_LABELS_JSON` when available.
- Lightweight or fork-sensitive checks:
  - Keep on `ubuntu-latest`.

Fallback behavior is required:
- If `ALCOVE_RUNNER_LABELS_JSON` is unset, run on `ubuntu-latest`.

## Rollout Stages

1. Stage 0: Baseline
   - Record 14-day runtime inventory.
2. Stage 1: Enable runner variable
   - Set `ALCOVE_RUNNER_LABELS_JSON=["self-hosted","linux","x64","cpu-default"]`.
   - Monitor workflow success/latency for 1 week.
3. Stage 2: Expand to target repos
   - Apply the same runner-label variable pattern in `alcove-private` and `alcove-demo`.
4. Stage 3: Tighten churn controls
   - Add/verify `concurrency` and `paths` filters across active workflows.
5. Stage 4: Review
   - Confirm hosted minutes reduced by at least 50% on migrated jobs.
   - Confirm no increase in median PR wait time.

## Rate-Limit Controls

- Use REST-first automation (`gh api`) in scripts and workflows.
- Route GitHub API calls through `scripts/ops/gh_api_retry.sh` for bounded retry with jitter.
- Avoid high fan-out parallel writes (cap matrix parallelism when needed).
- Keep scheduled jobs offset by minute to avoid top-of-hour spikes.

## Exit Criteria

- Self-hosted runner flow stable for 2 weeks.
- No recurring secondary rate-limit failures.
- Required checks passing and predictable.
