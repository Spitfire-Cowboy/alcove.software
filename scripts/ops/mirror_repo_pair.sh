#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_REPO:?SOURCE_REPO is required (e.g. Pro777/alcove-private)}"
: "${DEST_REPO:?DEST_REPO is required (e.g. Spitfire-Cowboy/alcove-private)}"
: "${SOURCE_TOKEN:?SOURCE_TOKEN is required}"

DEST_TOKEN="${DEST_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -z "$DEST_TOKEN" ]]; then
  echo "DEST_TOKEN or GITHUB_TOKEN must be set" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

mirror="$tmp_dir/mirror.git"
git init --bare "$mirror" >/dev/null

git -C "$mirror" remote add source "https://x-access-token:${SOURCE_TOKEN}@github.com/${SOURCE_REPO}.git"
git -C "$mirror" remote add dest "https://x-access-token:${DEST_TOKEN}@github.com/${DEST_REPO}.git"

# Fetch source refs (heads + tags only). Hidden refs such as refs/pull/* are intentionally excluded.
git -C "$mirror" fetch --prune source \
  '+refs/heads/*:refs/heads/*' \
  '+refs/tags/*:refs/tags/*'

# Push source refs into destination, pruning branches/tags removed in source.
git -C "$mirror" push --prune dest \
  '+refs/heads/*:refs/heads/*' \
  '+refs/tags/*:refs/tags/*'

echo "Mirror complete: ${SOURCE_REPO} -> ${DEST_REPO}"
