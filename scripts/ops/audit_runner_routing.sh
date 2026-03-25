#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
WORKFLOWS_DIR="$ROOT_DIR/.github/workflows"

heavy_workflows=(
  "mirror-pro777-repos.yml"
  "mirror-parity-check.yml"
  "weekly-mirror-health.yml"
  "enforce-repo-policy.yml"
  "secret-rotation-check.yml"
  "cutover-verification.yml"
)

hosted_workflows=(
  "ci.yml"
  "pages.yml"
)

failures=0

check_file() {
  local file="$1"
  if [[ ! -f "$WORKFLOWS_DIR/$file" ]]; then
    echo "FAIL: missing workflow file $file" >&2
    failures=$((failures + 1))
    return 1
  fi
  return 0
}

for wf in "${heavy_workflows[@]}"; do
  check_file "$wf" || continue

  if ! grep -q "ALCOVE_RUNNER_LABELS_JSON" "$WORKFLOWS_DIR/$wf"; then
    echo "FAIL: $wf missing self-hosted routing variable" >&2
    failures=$((failures + 1))
    continue
  fi
  if ! grep -q "ubuntu-latest" "$WORKFLOWS_DIR/$wf"; then
    echo "FAIL: $wf missing ubuntu-latest fallback" >&2
    failures=$((failures + 1))
    continue
  fi
  echo "OK: $wf has self-hosted route + fallback"
done

for wf in "${hosted_workflows[@]}"; do
  check_file "$wf" || continue
  if grep -q "ALCOVE_RUNNER_LABELS_JSON" "$WORKFLOWS_DIR/$wf"; then
    echo "FAIL: $wf should remain hosted-only but includes runner variable" >&2
    failures=$((failures + 1))
    continue
  fi
  if ! grep -q "ubuntu-latest" "$WORKFLOWS_DIR/$wf"; then
    echo "FAIL: $wf expected ubuntu-latest runner" >&2
    failures=$((failures + 1))
    continue
  fi
  echo "OK: $wf remains hosted-only"
done

if (( failures > 0 )); then
  echo "Runner routing audit failed (${failures} issues)." >&2
  exit 1
fi

echo "Runner routing audit passed."
