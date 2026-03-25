#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a Hetzner host for the runner fleet.
# Usage:
#   sudo ./bootstrap_host.sh [/opt/runner-fleet]

TARGET_DIR="${1:-/opt/runner-fleet}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${EUID}" -ne 0 ]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This bootstrap script currently supports Debian/Ubuntu hosts only." >&2
  exit 1
fi

echo "[bootstrap] Installing base packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  docker.io \
  docker-compose-plugin \
  gh \
  jq \
  rsync \
  ufw

echo "[bootstrap] Enabling Docker..."
systemctl enable --now docker

echo "[bootstrap] Preparing fleet directory at ${TARGET_DIR}..."
mkdir -p "${TARGET_DIR}"
rsync -a --delete \
  --filter 'P .env' \
  --exclude 'runner-data/' \
  "${SCRIPT_DIR}/" "${TARGET_DIR}/"

if [ ! -f "${TARGET_DIR}/.env" ]; then
  cp "${TARGET_DIR}/.env.example" "${TARGET_DIR}/.env"
  echo "[bootstrap] Created ${TARGET_DIR}/.env from template."
fi

echo "[bootstrap] Installing systemd units..."
install -m 0644 "${TARGET_DIR}/systemd/runner-fleet.service" /etc/systemd/system/runner-fleet.service
install -m 0644 "${TARGET_DIR}/systemd/runner-cleanup.service" /etc/systemd/system/runner-cleanup.service
install -m 0644 "${TARGET_DIR}/systemd/runner-cleanup.timer" /etc/systemd/system/runner-cleanup.timer
systemctl daemon-reload
systemctl enable --now runner-cleanup.timer

cat <<EOF
[bootstrap] Complete.

Next steps:
1) Edit ${TARGET_DIR}/.env and set ACCESS_TOKEN.
2) Optionally harden host firewall:
   sudo ${TARGET_DIR}/harden_firewall.sh
3) Start runner fleet:
   sudo systemctl enable --now runner-fleet.service
4) Verify runner registration:
   ORG_NAME=Spitfire-Cowboy ${TARGET_DIR}/check_runner_registration.sh
EOF
