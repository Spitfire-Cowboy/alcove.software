#!/usr/bin/env bash
set -euo pipefail

ORG_NAME="${ORG_NAME:-Spitfire-Cowboy}"

if [ -z "${GH_TOKEN:-}" ]; then
  echo "Set GH_TOKEN with org-level runner read/admin access." >&2
  exit 1
fi

json="$(gh api "orgs/${ORG_NAME}/actions/runners?per_page=100")"

total="$(jq '.total_count' <<< "${json}")"
online="$(jq '[.runners[] | select(.status=="online")] | length' <<< "${json}")"

echo "org=${ORG_NAME}"
echo "total_runners=${total}"
echo "online_runners=${online}"
echo
echo "labels:"
jq -r '
  [.runners[] | .labels[]?.name]
  | sort
  | group_by(.)
  | map("\(.[0])=\(length)")
  | .[]
' <<< "${json}"

