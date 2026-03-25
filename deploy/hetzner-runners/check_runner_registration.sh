#!/usr/bin/env bash
set -euo pipefail

ORG_NAME="${ORG_NAME:-Spitfire-Cowboy}"

if [ -z "${GH_TOKEN:-}" ]; then
  echo "Set GH_TOKEN with org-level runner read/admin access." >&2
  exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT
echo "[]" > "$tmp_file"

page=1
while true; do
  resp="$(gh api "orgs/${ORG_NAME}/actions/runners?per_page=100&page=${page}")"
  page_count="$(jq '.runners | length' <<< "${resp}")"
  if [ "${page_count}" -eq 0 ]; then
    break
  fi

  jq -s '.[0] + .[1]' "$tmp_file" <(jq '.runners' <<< "${resp}") > "${tmp_file}.new"
  mv "${tmp_file}.new" "$tmp_file"
  page=$((page + 1))
done

total="$(jq 'length' "$tmp_file")"
online="$(jq '[.[] | select(.status=="online")] | length' "$tmp_file")"

echo "org=${ORG_NAME}"
echo "total_runners=${total}"
echo "online_runners=${online}"
echo
echo "labels:"
jq -r '
  [.[] | .labels[]?.name]
  | sort
  | group_by(.)
  | map("\(.[0])=\(length)")
  | .[]
' "$tmp_file"
