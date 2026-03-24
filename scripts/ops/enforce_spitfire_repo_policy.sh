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

  gh api --method PATCH "/repos/${repo}" \
    -f private=true \
    -f allow_forking=false \
    -f default_branch="${default_branch}" \
    --jq '{full_name,private,visibility,allow_forking,default_branch}'

done
