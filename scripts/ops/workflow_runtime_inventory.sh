#!/usr/bin/env bash
set -euo pipefail

# Build a workflow runtime/cost inventory using GitHub REST APIs only.
# Example:
#   ORG=Spitfire-Cowboy REPOS="alcove-private alcove-demo" DAYS=14 ./scripts/ops/workflow_runtime_inventory.sh

ORG="${ORG:-Spitfire-Cowboy}"
REPOS="${REPOS:-alcove-private alcove-demo}"
DAYS="${DAYS:-14}"
OPS_DIR="$(cd "$(dirname "$0")" && pwd)"
GH_API_RETRY="${OPS_DIR}/gh_api_retry.sh"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "DAYS must be a non-negative integer" >&2
  exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

for repo in $REPOS; do
  "$GH_API_RETRY" "repos/${ORG}/${repo}/actions/runs?per_page=100" \
    | jq -c \
      --arg repo "$repo" \
      --argjson days "$DAYS" \
      '
      .workflow_runs[]
      | select(((now - (.created_at | fromdateiso8601)) / 86400) <= $days)
      | {
          repo: $repo,
          workflow: .name,
          status: .status,
          duration_sec: (
            if .run_started_at and .updated_at
            then ((.updated_at | fromdateiso8601) - (.run_started_at | fromdateiso8601))
            else 0
            end
          )
        }
      ' >> "$tmp_file"
done

echo "# Workflow Runtime Inventory (${ORG}, last ${DAYS} days)"
echo
echo "| Repo | Workflow | Runs | Completed | Avg Duration (min) | Total Runtime (min) |"
echo "| --- | --- | ---: | ---: | ---: | ---: |"

if [ ! -s "$tmp_file" ]; then
  echo "| n/a | n/a | 0 | 0 | 0.00 | 0.00 |"
  exit 0
fi

jq -r -s '
  group_by(.repo + "|" + .workflow)
  | map({
      repo: .[0].repo,
      workflow: .[0].workflow,
      runs: length,
      completed: map(select(.status=="completed")) | length,
      total_sec: (map(.duration_sec) | add),
      avg_sec: ((map(.duration_sec) | add) / length)
    })
  | sort_by(.repo, .workflow)
  | .[]
  | "| \(.repo) | \(.workflow) | \(.runs) | \(.completed) | \((.avg_sec/60)|tostring) | \((.total_sec/60)|tostring) |"
' "$tmp_file" \
  | awk -F'|' 'BEGIN{OFS="|"}{
      if (NF > 1) {
        for (i=1; i<=NF; i++) gsub(/^ +| +$/, "", $i)
        if ($1=="") {
          if ($6 ~ /^[0-9.]+$/) $6=sprintf("%.2f",$6)
          if ($7 ~ /^[0-9.]+$/) $7=sprintf("%.2f",$7)
        }
      }
      print
    }'
