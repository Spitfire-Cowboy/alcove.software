#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"

repos=(
  "Spitfire-Cowboy/alcove-private:develop"
  "Spitfire-Cowboy/alcove-demo:main"
)

for entry in "${repos[@]}"; do
  repo="${entry%%:*}"
  default_branch="${entry##*:}"

  echo "Enforcing policy for ${repo}"

  # Primary patch: enforce private visibility and default branch.
  gh api --method PATCH "/repos/${repo}" \
    -f private=true \
    -f default_branch="${default_branch}" \
    --jq '{full_name,private,visibility,allow_forking,default_branch}'

  # Secondary patch: allow_forking=false. Some orgs block this write for private repos.
  set +e
  out=$(gh api --method PATCH "/repos/${repo}" -f allow_forking=false 2>&1)
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    if [[ "$out" == *"does not allow private repository forking"* ]]; then
      echo "Org-level policy already disables private forking for ${repo}; skipping allow_forking write"
    else
      echo "$out" >&2
      exit $rc
    fi
  fi

done
