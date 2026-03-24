# Spitfire-Cowboy Cutover Checklist

Use this checklist for completing migration from `Pro777/*` to `Spitfire-Cowboy/*`.

## 1) Mirror Baseline

- [ ] Scheduled mirror workflow passes in `Spitfire-Cowboy/alcove.software`.
- [ ] Manual workflow dispatch passes for both repo pairs.
- [ ] Branch/tag counts match between source and destination.
- [ ] Default branch commit SHAs match per repo.

## 2) Secrets and Environments

- [ ] `PRO777_MIRROR_PAT` set and documented owner/expiry.
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
- [ ] Move heavy jobs to `self-hosted` labels.
- [ ] Keep fork-safe/minimal checks on GitHub-hosted runners.
- [ ] Add workflow `concurrency` and `paths` filters where possible.

## 5) Integrations and Webhooks

- [ ] Reinstall/re-authorize GitHub Apps in destination repos.
- [ ] Recreate webhooks and verify signatures.
- [ ] Rebind deployment integrations (Cloudflare/Hetzner/registries).
- [ ] Validate status checks and bot comments originate from destination repos.

## 6) Cutover Execution

- [ ] Announce freeze window and stop source writes.
- [ ] Run final manual mirror workflow.
- [ ] Switch docs/remotes/automation to `Spitfire-Cowboy/*` canonical URLs.
- [ ] Monitor for 7-14 days and then archive/lock source repos.
