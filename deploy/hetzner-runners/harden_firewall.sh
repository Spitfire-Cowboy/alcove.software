#!/usr/bin/env bash
set -euo pipefail

# Basic UFW hardening for runner hosts.
# Optional:
#   ADMIN_CIDRS="203.0.113.10/32,198.51.100.0/24" sudo ./harden_firewall.sh

if [ "${EUID}" -ne 0 ]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
  echo "ufw not installed. Install first." >&2
  exit 1
fi

echo "[firewall] applying baseline policy..."
echo "[firewall] WARNING: this can reset existing UFW rules"
ufw_state="$(ufw status | head -n1 | awk '{print tolower($2)}')"
if [ "${ufw_state}" != "inactive" ] && [ "${ALLOW_UFW_RESET:-0}" != "1" ]; then
  echo "UFW is active. Re-run with ALLOW_UFW_RESET=1 to confirm reset." >&2
  exit 1
fi

ufw --force reset >/dev/null
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null

# SSH access: restrict if ADMIN_CIDRS is set, otherwise allow all (safer bootstrap default).
if [ -n "${ADMIN_CIDRS:-}" ]; then
  IFS=',' read -r -a cidrs <<< "${ADMIN_CIDRS}"
  for cidr in "${cidrs[@]}"; do
    ufw allow proto tcp from "${cidr}" to any port 22 >/dev/null
  done
else
  ufw allow 22/tcp >/dev/null
fi

# Optional egress hardening profile (common CI network needs).
if [ "${STRICT_EGRESS:-0}" = "1" ]; then
  ufw default deny outgoing >/dev/null
  ufw allow out 53 >/dev/null
  ufw allow out 123/udp >/dev/null
  ufw allow out 80/tcp >/dev/null
  ufw allow out 443/tcp >/dev/null
fi

ufw --force enable >/dev/null
ufw status verbose
