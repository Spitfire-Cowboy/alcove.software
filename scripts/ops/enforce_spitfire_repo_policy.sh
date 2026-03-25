#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"
OPS_DIR="$(cd "$(dirname "$0")" && pwd)"
GH_API_RETRY="${OPS_DIR}/gh_api_retry.sh"

repos=(
  "Spitfire-Cowboy/alcove:main:false"
  "Spitfire-Cowboy/alcove-private:develop:true"
  "Spitfire-Cowboy/alcove-demo:main:true"
)

for entry in "${repos[@]}"; do
  repo="${entry%%:*}"
  rest="${entry#*:}"
  default_branch="${rest%%:*}"
  is_private="${rest##*:}"

  echo "Enforcing policy for ${repo}"

  # Primary patch: enforce visibility and default branch.
  "$GH_API_RETRY" --method PATCH "/repos/${repo}" \
    -f private="${is_private}" \
    -f default_branch="${default_branch}" \
    --jq '{full_name,private,visibility,allow_forking,default_branch}'

  if [[ "${is_private}" == "true" ]]; then
    # Secondary patch: allow_forking=false. Some orgs block this write for private repos.
    set +e
    out=$("$GH_API_RETRY" --method PATCH "/repos/${repo}" -f allow_forking=false 2>&1)
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
  fi

done
