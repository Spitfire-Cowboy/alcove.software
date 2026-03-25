# Self-Hosted Runners (Hetzner Baseline)

This baseline is for reducing GitHub-hosted Actions usage for `Spitfire-Cowboy` repos.

## Goals

- Offload heavy CI jobs to Hetzner-managed runners.
- Keep lightweight/fork-safe checks on GitHub-hosted runners.
- Use ephemeral runners where possible to reduce persistence risk.

## Files

- `deploy/hetzner-runners/bootstrap_host.sh`
- `deploy/hetzner-runners/docker-compose.yml`
- `deploy/hetzner-runners/.env.example`
- `deploy/hetzner-runners/harden_firewall.sh`
- `deploy/hetzner-runners/cleanup_runner_data.sh`
- `deploy/hetzner-runners/check_runner_registration.sh`
- `deploy/hetzner-runners/systemd/runner-fleet.service`
- `deploy/hetzner-runners/systemd/runner-cleanup.service`
- `deploy/hetzner-runners/systemd/runner-cleanup.timer`
- `docs/ops/RUNNER_INCIDENT_RESPONSE.md`

## Quick Start

1. Provision a Hetzner VM (Ubuntu 24.04+).
2. Run bootstrap from this repo:
   - `sudo deploy/hetzner-runners/bootstrap_host.sh`
3. Edit `/opt/runner-fleet/.env` and set `ACCESS_TOKEN`.
4. Optionally apply firewall baseline:
   - `sudo ALLOW_UFW_RESET=1 /opt/runner-fleet/harden_firewall.sh`
5. Start services:
   - `sudo systemctl enable --now runner-fleet.service`
6. Confirm runners appear in GitHub org settings with labels:
   - `cpu-default`
   - `high-mem`
7. Verify registration and online count:
   - `GH_TOKEN=... ORG_NAME=Spitfire-Cowboy /opt/runner-fleet/check_runner_registration.sh`

## Workflow Label Policy

Use explicit labels in workflows:

```yaml
runs-on: [self-hosted, linux, x64, cpu-default]
```

Keep these on GitHub-hosted runners:
- untrusted fork PR jobs
- lightweight lint/unit checks that need fast queue times

## Runner Selection Variable

Ops workflows in this repo now use a safe fallback selector:

- Repository/org variable: `ALCOVE_RUNNER_LABELS_JSON`
- Value example:
  - `["self-hosted","linux","x64","cpu-default"]`

Behavior:
- If `ALCOVE_RUNNER_LABELS_JSON` is set, workflows run on that label set.
- If unset, workflows fall back to `ubuntu-latest`.

This allows progressive cutover without editing workflow files for rollback.

## Hardening

- Restrict inbound SSH to trusted admin IPs only.
- Keep runners in a dedicated VPC/network segment.
- Enforce outbound allowlist where feasible.
- Rotate registration token/PAT regularly.
- Add job `timeout-minutes` and workflow `concurrency`.
- Enable cleanup timer:
  - `sudo systemctl enable --now runner-cleanup.timer`
- Practice incident response from:
  - `docs/ops/RUNNER_INCIDENT_RESPONSE.md`

## Rollout Sequence

1. Move one heavy non-critical workflow first.
2. Validate stability for one week.
3. Move remaining heavy jobs in batches.
4. Keep rollback path to GitHub-hosted runner labels.
5. Track workflow runtime and queue pressure with:
   - `scripts/ops/workflow_runtime_inventory.sh`
6. Restrict runner group repository access to:
   - `Spitfire-Cowboy/alcove-private`
   - `Spitfire-Cowboy/alcove-demo`
