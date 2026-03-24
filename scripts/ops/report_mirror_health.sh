#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_TOKEN:?SOURCE_TOKEN is required}"
: "${DEST_TOKEN:?DEST_TOKEN is required}"

pairs=(
  "Pro777/alcove-private Spitfire-Cowboy/alcove-private develop"
  "Pro777/alcove-demo Spitfire-Cowboy/alcove-demo main"
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
  echo "| Source | Destination | Branch | Heads | Tags | SHA Match |"
  echo "|---|---|---:|---:|---:|---|"

  overall_ok=1
  for row in "${pairs[@]}"; do
    read -r source_repo dest_repo default_branch <<<"$row"

    src_heads=$(git ls-remote --heads "$(src_url "$source_repo")" | wc -l | tr -d ' ')
    dst_heads=$(git ls-remote --heads "$(dst_url "$dest_repo")" | wc -l | tr -d ' ')
    src_tags=$(git ls-remote --tags "$(src_url "$source_repo")" | wc -l | tr -d ' ')
    dst_tags=$(git ls-remote --tags "$(dst_url "$dest_repo")" | wc -l | tr -d ' ')
    src_sha=$(git ls-remote --heads "$(src_url "$source_repo")" "$default_branch" | awk '{print $1}')
    dst_sha=$(git ls-remote --heads "$(dst_url "$dest_repo")" "$default_branch" | awk '{print $1}')

    heads_ok="no"
    tags_ok="no"
    sha_ok="no"
    [[ "$src_heads" == "$dst_heads" ]] && heads_ok="yes"
    [[ "$src_tags" == "$dst_tags" ]] && tags_ok="yes"
    [[ "$src_sha" == "$dst_sha" ]] && sha_ok="yes"

    [[ "$heads_ok" == "yes" && "$tags_ok" == "yes" && "$sha_ok" == "yes" ]] || overall_ok=0

    echo "| ${source_repo} | ${dest_repo} | ${default_branch} | ${src_heads}/${dst_heads} (${heads_ok}) | ${src_tags}/${dst_tags} (${tags_ok}) | ${sha_ok} |"
  done

  echo
  if [[ "$overall_ok" -eq 1 ]]; then
    echo "Status: healthy"
  else
    echo "Status: drift detected"
  fi
} > "$report_file"

echo "$report_file"
