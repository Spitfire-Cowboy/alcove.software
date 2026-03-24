# Secret Rotation Policy

Repository: `Spitfire-Cowboy/alcove.software`

Managed secrets:

- `PRO777_MIRROR_PAT` (source read)
- `SPITFIRE_MIRROR_PAT` (destination read/settings automation)
- `SPITFIRE_MIRROR_SSH_KEY` (destination mirror push auth)

## Automation

- Workflow: `.github/workflows/secret-rotation-check.yml`
- Script: `scripts/ops/check_secret_age.sh`
- Default maximum age: 30 days

If required secrets are missing or older than threshold, automation opens an issue.

## Rotation Procedure

1. Mint replacement fine-grained tokens and SSH key material with least privilege.
2. Update repo secrets in `alcove.software`.
3. Re-run:
   - `mirror-pro777-repos`
   - `mirror-parity-check`
   - `enforce-repo-policy`
4. Revoke old tokens/keys.
