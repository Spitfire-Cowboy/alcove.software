# Self-Hosted Runners (Hetzner Baseline)

This baseline is for reducing GitHub-hosted Actions usage for `Spitfire-Cowboy` repos.

## Goals

- Offload heavy CI jobs to Hetzner-managed runners.
- Keep lightweight/fork-safe checks on GitHub-hosted runners.
- Use ephemeral runners where possible to reduce persistence risk.

## Files

- `deploy/hetzner-runners/docker-compose.yml`
- `deploy/hetzner-runners/.env.example`
- `deploy/hetzner-runners/systemd/runner-fleet.service`

## Quick Start

1. Provision a Hetzner VM (Ubuntu 24.04+).
2. Install Docker + Compose plugin.
3. Copy `deploy/hetzner-runners/` to `/opt/runner-fleet`.
4. Create `/opt/runner-fleet/.env` from `.env.example`.
5. Start services:
   - `docker compose up -d`
6. Confirm runners appear in GitHub org settings with labels:
   - `cpu-default`
   - `high-mem`

## Workflow Label Policy

Use explicit labels in workflows:

```yaml
runs-on: [self-hosted, linux, x64, cpu-default]
```

Keep these on GitHub-hosted runners:
- untrusted fork PR jobs
- lightweight lint/unit checks that need fast queue times

## Hardening

- Restrict inbound SSH to trusted admin IPs only.
- Keep runners in a dedicated VPC/network segment.
- Enforce outbound allowlist where feasible.
- Rotate registration token/PAT regularly.
- Add job `timeout-minutes` and workflow `concurrency`.

## Rollout Sequence

1. Move one heavy non-critical workflow first.
2. Validate stability for one week.
3. Move remaining heavy jobs in batches.
4. Keep rollback path to GitHub-hosted runner labels.
