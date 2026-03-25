#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER_DATA_DIR="${RUNNER_DATA_DIR:-${SCRIPT_DIR}/runner-data}"
WORK_TTL_DAYS="${WORK_TTL_DAYS:-2}"

echo "[cleanup] pruning stale Docker artifacts..."
docker container prune -f --filter "until=24h" >/dev/null || true
docker image prune -f --filter "until=168h" >/dev/null || true
docker volume prune -f >/dev/null || true

if [ -d "${RUNNER_DATA_DIR}" ]; then
  echo "[cleanup] cleaning runner work directories older than ${WORK_TTL_DAYS} day(s)..."
  find "${RUNNER_DATA_DIR}" -type d -name "_work" | while IFS= read -r work_dir; do
    find "${work_dir}" -mindepth 1 -maxdepth 1 -mtime +"${WORK_TTL_DAYS}" -exec rm -rf {} +
  done
fi

echo "[cleanup] complete"

