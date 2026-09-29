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

fail=0

for row in "${pairs[@]}"; do
  IFS='|' read -r mode source_repo dest_repo default_branch sync_branch <<<"$row"
  echo "Checking ${source_repo} -> ${dest_repo} (${mode})"

  src_heads=$(git ls-remote --heads "$(src_url "$source_repo")" | wc -l | tr -d ' ')
  dst_heads=$(git ls-remote --heads "$(dst_url "$dest_repo")" | wc -l | tr -d ' ')
  src_tags=$(git ls-remote --tags "$(src_url "$source_repo")" | wc -l | tr -d ' ')
  dst_tags=$(git ls-remote --tags "$(dst_url "$dest_repo")" | wc -l | tr -d ' ')

  src_sha=$(git ls-remote --heads "$(src_url "$source_repo")" "$default_branch" | awk '{print $1}')
  dst_sha=$(git ls-remote --heads "$(dst_url "$dest_repo")" "$default_branch" | awk '{print $1}')

  if [[ "$mode" == "direct" ]]; then
    echo "heads ${src_heads}/${dst_heads} tags ${src_tags}/${dst_tags} ${default_branch} ${src_sha}/${dst_sha}"

    if [[ "$src_heads" != "$dst_heads" || "$src_tags" != "$dst_tags" || "$src_sha" != "$dst_sha" ]]; then
      echo "PARITY_MISMATCH ${source_repo} ${dest_repo}" >&2
      fail=1
    fi
  elif [[ "$mode" == "pull_request" ]]; then
    pr_number="$(GH_TOKEN="$DEST_TOKEN" gh pr list --repo "$dest_repo" --state open --head "$sync_branch" --base "$default_branch" --json number --jq '.[0].number // ""')"
    pr_head_sha="$(GH_TOKEN="$DEST_TOKEN" gh pr list --repo "$dest_repo" --state open --head "$sync_branch" --base "$default_branch" --json headRefOid --jq '.[0].headRefOid // ""')"

    if [[ "$src_sha" == "$dst_sha" ]]; then
      echo "base ${default_branch} matches source @ ${src_sha}"
    elif [[ -n "$pr_number" && "$pr_head_sha" == "$src_sha" ]]; then
      echo "pending PR #${pr_number}: ${sync_branch} @ ${pr_head_sha} -> ${default_branch} (${dst_sha})"
    else
      echo "PARITY_MISMATCH ${source_repo} ${dest_repo} (expected open PR from ${sync_branch} carrying ${src_sha})" >&2
      fail=1
    fi
  else
    echo "Unsupported parity mode: $mode" >&2
    fail=1
  fi
  echo
 done

exit "$fail"
