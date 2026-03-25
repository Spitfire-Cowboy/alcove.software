#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"

repo="Spitfire-Cowboy/alcove.software"
max_age_days="${MAX_SECRET_AGE_DAYS:-30}"
required_secrets=(
  "SPITFIRE_MIRROR_PAT"
  "PRO777_MIRROR_PAT"
)
ssh_key_candidates=(
  "PRO777_MIRROR_SSH_KEY"
  "SPITFIRE_MIRROR_SSH_KEY"
)

json=$(gh api "/repos/${repo}/actions/secrets?per_page=100")
now_epoch=$(date -u +%s)
violations=0

echo "# Secret Age Report"
echo

echo "Repository: ${repo}"
echo "Max age: ${max_age_days} days"
echo

echo "| Secret | Updated (UTC) | Age (days) | Status |"
echo "|---|---|---:|---|"

for name in "${required_secrets[@]}"; do
  updated_at=$(jq -r --arg n "$name" '.secrets[] | select(.name==$n) | .updated_at' <<<"$json")

  if [[ -z "$updated_at" || "$updated_at" == "null" ]]; then
    echo "| ${name} | missing | n/a | missing |"
    violations=1
    continue
  fi

  updated_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated_at" +%s 2>/dev/null || date -u -d "$updated_at" +%s)
  age_days=$(( (now_epoch - updated_epoch) / 86400 ))
  status="ok"
  if (( age_days > max_age_days )); then
    status="rotate"
    violations=1
  fi

  echo "| ${name} | ${updated_at} | ${age_days} | ${status} |"
done

ssh_secret_name=""
ssh_secret_updated_at=""
for name in "${ssh_key_candidates[@]}"; do
  updated_at=$(jq -r --arg n "$name" '.secrets[] | select(.name==$n) | .updated_at' <<<"$json")
  if [[ -n "$updated_at" && "$updated_at" != "null" ]]; then
    ssh_secret_name="$name"
    ssh_secret_updated_at="$updated_at"
    break
  fi
done

if [[ -z "$ssh_secret_name" ]]; then
  echo "| mirror-destination-ssh-key | missing (${ssh_key_candidates[*]}) | n/a | missing |"
  violations=1
else
  updated_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$ssh_secret_updated_at" +%s 2>/dev/null || date -u -d "$ssh_secret_updated_at" +%s)
  age_days=$(( (now_epoch - updated_epoch) / 86400 ))
  status="ok"
  if (( age_days > max_age_days )); then
    status="rotate"
    violations=1
  fi
  echo "| mirror-destination-ssh-key (${ssh_secret_name}) | ${ssh_secret_updated_at} | ${age_days} | ${status} |"
fi

if (( violations > 0 )); then
  exit 2
fi
