#!/usr/bin/env bash
set -euo pipefail

pairs=(
  "Pro777/alcove-private Spitfire-Cowboy/alcove-private develop"
  "Pro777/alcove-demo Spitfire-Cowboy/alcove-demo main"
)

fail=0

for row in "${pairs[@]}"; do
  read -r source_repo dest_repo default_branch <<<"$row"
  echo "Checking ${source_repo} -> ${dest_repo}"

  src_heads=$(git ls-remote --heads "git@github.com:${source_repo}.git" | wc -l | tr -d ' ')
  dst_heads=$(git ls-remote --heads "git@github.com:${dest_repo}.git" | wc -l | tr -d ' ')
  src_tags=$(git ls-remote --tags "git@github.com:${source_repo}.git" | wc -l | tr -d ' ')
  dst_tags=$(git ls-remote --tags "git@github.com:${dest_repo}.git" | wc -l | tr -d ' ')

  src_sha=$(git ls-remote --heads "git@github.com:${source_repo}.git" "$default_branch" | awk '{print $1}')
  dst_sha=$(git ls-remote --heads "git@github.com:${dest_repo}.git" "$default_branch" | awk '{print $1}')

  echo "heads ${src_heads}/${dst_heads} tags ${src_tags}/${dst_tags} ${default_branch} ${src_sha}/${dst_sha}"

  if [[ "$src_heads" != "$dst_heads" || "$src_tags" != "$dst_tags" || "$src_sha" != "$dst_sha" ]]; then
    echo "PARITY_MISMATCH ${source_repo} ${dest_repo}" >&2
    fail=1
  fi
  echo
 done

exit "$fail"
