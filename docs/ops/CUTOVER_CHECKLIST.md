# Spitfire-Cowboy Cutover Checklist

Use this checklist for operating with `Spitfire-Cowboy/*` as canonical and `Pro777/*` as mirrors.

## 1) Mirror Baseline

- [ ] Scheduled mirror workflow passes in `Spitfire-Cowboy/alcove.software`.
- [ ] Manual workflow dispatch passes for all configured repo pairs (`alcove`, `alcove-private`, `alcove-demo`).
- [ ] Branch/tag counts match between source and destination.
- [ ] Default branch commit SHAs match per repo.

## 2) Secrets and Environments

- [ ] `SPITFIRE_MIRROR_PAT` set and documented owner/expiry.
- [ ] `PRO777_MIRROR_PAT` set and documented owner/expiry.
- [ ] Destination SSH key secret present (`PRO777_MIRROR_SSH_KEY`, or fallback `SPITFIRE_MIRROR_SSH_KEY`).
- [ ] Destination repos have all required Actions secrets.
- [ ] Destination repos have all required environment secrets/approvals.
- [ ] Rotate mirror PAT to least privilege after initial validation.

## 3) Branch Protection

- [ ] Recreate/verify required checks on destination default branches.
- [ ] Enforce PR review requirements.
- [ ] Restrict direct pushes and force pushes.
- [ ] Confirm admin/bypass settings are intentional.

## 4) Runners and CI Cost Control

- [ ] Register self-hosted runner groups in `Spitfire-Cowboy`.
- [ ] Set `ALCOVE_RUNNER_LABELS_JSON` (repo/org variable) for controlled self-hosted routing.
- [ ] Move heavy jobs to `self-hosted` labels.
- [ ] Keep fork-safe/minimal checks on GitHub-hosted runners.
- [ ] Run `./scripts/ops/audit_runner_routing.sh` and verify `runner-routing-audit` workflow is passing.
- [ ] Add workflow `concurrency` and `paths` filters where possible.
- [ ] Capture baseline and weekly runtime snapshots with `scripts/ops/workflow_runtime_inventory.sh`.
- [ ] Enable and verify `runner-cleanup.timer` on Hetzner hosts.
- [ ] Run one incident-response drill from `docs/ops/RUNNER_INCIDENT_RESPONSE.md`.

## 5) Integrations and Webhooks

- [ ] Reinstall/re-authorize GitHub Apps in destination repos.
- [ ] Recreate webhooks and verify signatures.
- [ ] Rebind deployment integrations (Cloudflare/Hetzner/registries).
- [ ] Validate status checks and bot comments originate from destination repos.

## 6) Cutover Execution

- [ ] Announce freeze window and stop destination (`Pro777/*`) writes.
- [ ] Run final manual mirror workflow.
- [ ] Switch docs/remotes/automation to `Spitfire-Cowboy/*` canonical URLs.
- [ ] Monitor for 7-14 days and then archive/lock destination mirror repos if no longer needed.
