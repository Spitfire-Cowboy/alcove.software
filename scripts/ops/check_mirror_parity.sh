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

fail=0

for row in "${pairs[@]}"; do
  read -r source_repo dest_repo default_branch <<<"$row"
  echo "Checking ${source_repo} -> ${dest_repo}"

  src_heads=$(git ls-remote --heads "$(src_url "$source_repo")" | wc -l | tr -d ' ')
  dst_heads=$(git ls-remote --heads "$(dst_url "$dest_repo")" | wc -l | tr -d ' ')
  src_tags=$(git ls-remote --tags "$(src_url "$source_repo")" | wc -l | tr -d ' ')
  dst_tags=$(git ls-remote --tags "$(dst_url "$dest_repo")" | wc -l | tr -d ' ')

  src_sha=$(git ls-remote --heads "$(src_url "$source_repo")" "$default_branch" | awk '{print $1}')
  dst_sha=$(git ls-remote --heads "$(dst_url "$dest_repo")" "$default_branch" | awk '{print $1}')

  echo "heads ${src_heads}/${dst_heads} tags ${src_tags}/${dst_tags} ${default_branch} ${src_sha}/${dst_sha}"

  if [[ "$src_heads" != "$dst_heads" || "$src_tags" != "$dst_tags" || "$src_sha" != "$dst_sha" ]]; then
    echo "PARITY_MISMATCH ${source_repo} ${dest_repo}" >&2
    fail=1
  fi
  echo
 done

exit "$fail"
