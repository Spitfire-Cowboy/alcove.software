#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_TOKEN:?SOURCE_TOKEN is required}"
: "${DEST_TOKEN:?DEST_TOKEN is required}"

pairs=(
  "direct|Spitfire-Cowboy/alcove|Pro777/alcove|main|"
  "pull_request|Spitfire-Cowboy/alcove-private|Pro777/alcove-private|develop|mirror/spitfire-alcove-private-develop"
  "direct|Spitfire-Cowboy/alcove-demo|Pro777/alcove-demo|main|"
)

src_url() {
  local repo="$1"
  echo "https://x-access-token:${SOURCE_TOKEN}@github.com/${repo}.git"
}

dst_url() {
  local repo="$1"
  echo "https://x-access-token:${DEST_TOKEN}@github.com/${repo}.git"
}

now_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
report_file="${RUNNER_TEMP:-/tmp}/mirror-health-report.md"

{
  echo "# Weekly Mirror Health"
  echo
  echo "Generated: ${now_utc}"
  echo
  echo "| Source | Destination | Mode | Branch | Heads | Tags | Status |"
  echo "|---|---|---|---:|---:|---:|---|"

  overall_ok=1
  for row in "${pairs[@]}"; do
    IFS='|' read -r mode source_repo dest_repo default_branch sync_branch <<<"$row"

    src_heads=$(git ls-remote --heads "$(src_url "$source_repo")" | wc -l | tr -d ' ')
    dst_heads=$(git ls-remote --heads "$(dst_url "$dest_repo")" | wc -l | tr -d ' ')
    src_tags=$(git ls-remote --tags "$(src_url "$source_repo")" | wc -l | tr -d ' ')
    dst_tags=$(git ls-remote --tags "$(dst_url "$dest_repo")" | wc -l | tr -d ' ')
    src_sha=$(git ls-remote --heads "$(src_url "$source_repo")" "$default_branch" | awk '{print $1}')
    dst_sha=$(git ls-remote --heads "$(dst_url "$dest_repo")" "$default_branch" | awk '{print $1}')

    if [[ "$mode" == "direct" ]]; then
      heads_ok="no"
      tags_ok="no"
      sha_ok="no"
      [[ "$src_heads" == "$dst_heads" ]] && heads_ok="yes"
      [[ "$src_tags" == "$dst_tags" ]] && tags_ok="yes"
      [[ "$src_sha" == "$dst_sha" ]] && sha_ok="yes"
      status="sha=${sha_ok}"

      [[ "$heads_ok" == "yes" && "$tags_ok" == "yes" && "$sha_ok" == "yes" ]] || overall_ok=0

      echo "| ${source_repo} | ${dest_repo} | ${mode} | ${default_branch} | ${src_heads}/${dst_heads} (${heads_ok}) | ${src_tags}/${dst_tags} (${tags_ok}) | ${status} |"
    elif [[ "$mode" == "pull_request" ]]; then
      pr_number="$(GH_TOKEN="$DEST_TOKEN" gh pr list --repo "$dest_repo" --state open --head "$sync_branch" --base "$default_branch" --json number --jq '.[0].number // ""')"
      pr_head_sha="$(GH_TOKEN="$DEST_TOKEN" gh pr list --repo "$dest_repo" --state open --head "$sync_branch" --base "$default_branch" --json headRefOid --jq '.[0].headRefOid // ""')"

      heads_display="${src_heads}/${dst_heads} (n/a)"
      tags_display="${src_tags}/${dst_tags} (n/a)"
      if [[ "$src_sha" == "$dst_sha" ]]; then
        status="base matches source"
      elif [[ -n "$pr_number" && "$pr_head_sha" == "$src_sha" ]]; then
        status="pending PR #${pr_number}"
      else
        status="drift"
        overall_ok=0
      fi

      echo "| ${source_repo} | ${dest_repo} | ${mode} | ${default_branch} | ${heads_display} | ${tags_display} | ${status} |"
    else
      echo "| ${source_repo} | ${dest_repo} | ${mode} | ${default_branch} | n/a | n/a | unsupported mode |"
      overall_ok=0
    fi
  done

  echo
  if [[ "$overall_ok" -eq 1 ]]; then
    echo "Status: healthy"
  else
    echo "Status: drift detected"
  fi
} > "$report_file"

echo "$report_file"
