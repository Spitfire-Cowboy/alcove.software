# Self-Hosted Runner Incident Response

Use this playbook for the Hetzner runner fleet in `Spitfire-Cowboy`.

## Triggers

- Suspicious job execution on self-hosted runners.
- Unexpected outbound network behavior.
- Repeated workflow failures tied to self-hosted labels.
- Credential leak or suspected token compromise.

## Immediate Containment (0-15 minutes)

1. Disable runner routing fallback variable:
   - Clear `ALCOVE_RUNNER_LABELS_JSON` (repo/org variable) so workflows revert to `ubuntu-latest`.
2. Stop runner fleet on impacted hosts:
   - `sudo systemctl stop runner-fleet.service`
3. If compromise suspected, isolate host network at provider firewall/VPC layer.
4. Disable or rotate runner registration token/PAT.

## Triage (15-60 minutes)

1. Capture host and workflow context:
   - `journalctl -u runner-fleet.service --since "2 hours ago"`
   - `docker ps -a`
   - `docker logs <runner-container>`
2. Check org runner state:
   - `GH_TOKEN=... ORG_NAME=Spitfire-Cowboy /opt/runner-fleet/check_runner_registration.sh`
3. Identify repos/workflows affected and switch critical pipelines to hosted runners until clear.

## Eradication and Recovery

1. Rotate secrets:
   - Runner registration PAT/token.
   - Any workflow secrets exposed to self-hosted jobs.
2. Rebuild host from known-good baseline.
3. Re-run bootstrap:
   - `sudo deploy/hetzner-runners/bootstrap_host.sh`
4. Re-enable fleet:
   - `sudo systemctl enable --now runner-fleet.service`
   - `sudo systemctl enable --now runner-cleanup.timer`
5. Restore `ALCOVE_RUNNER_LABELS_JSON` once post-rebuild checks pass.

## Post-Incident Checklist

- [ ] Root cause and timeline documented.
- [ ] Token rotation confirmation logged.
- [ ] Firewall and egress policy revalidated (`harden_firewall.sh`).
- [ ] Runner access scope reviewed (restrict to intended repos only).
- [ ] Follow-up hardening tasks created/tracked.

