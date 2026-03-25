#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_REPO:?SOURCE_REPO is required (e.g. Spitfire-Cowboy/alcove-private)}"
: "${DEST_REPO:?DEST_REPO is required (e.g. Pro777/alcove-private)}"
: "${SOURCE_TOKEN:?SOURCE_TOKEN is required}"

DEST_PUSH_MODE="${DEST_PUSH_MODE:-https}"
STRICT_PAIRING="${STRICT_PAIRING:-1}"
MAX_PRUNE_DELETIONS="${MAX_PRUNE_DELETIONS:-5}"
ALLOW_FORCE_MIRROR="${ALLOW_FORCE_MIRROR:-0}"

if ! [[ "$MAX_PRUNE_DELETIONS" =~ ^[0-9]+$ ]]; then
  echo "MAX_PRUNE_DELETIONS must be a non-negative integer" >&2
  exit 1
fi

if [[ "$STRICT_PAIRING" == "1" ]]; then
  if [[ "$SOURCE_REPO" != Spitfire-Cowboy/* ]]; then
    echo "STRICT_PAIRING=1 requires SOURCE_REPO under Spitfire-Cowboy/*" >&2
    exit 1
  fi
  if [[ "$DEST_REPO" != Pro777/* ]]; then
    echo "STRICT_PAIRING=1 requires DEST_REPO under Pro777/*" >&2
    exit 1
  fi
fi

if [[ "$DEST_PUSH_MODE" == "https" ]]; then
  DEST_TOKEN="${DEST_TOKEN:-${GITHUB_TOKEN:-}}"
  if [[ -z "$DEST_TOKEN" ]]; then
    echo "DEST_TOKEN or GITHUB_TOKEN must be set for https mode" >&2
    exit 1
  fi
  dest_remote="https://x-access-token:${DEST_TOKEN}@github.com/${DEST_REPO}.git"
elif [[ "$DEST_PUSH_MODE" == "ssh" ]]; then
  dest_remote="git@github.com:${DEST_REPO}.git"
else
  echo "Unsupported DEST_PUSH_MODE: $DEST_PUSH_MODE" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

mirror="$tmp_dir/mirror.git"
git init --bare "$mirror" >/dev/null

git -C "$mirror" remote add source "https://x-access-token:${SOURCE_TOKEN}@github.com/${SOURCE_REPO}.git"
git -C "$mirror" remote add dest "$dest_remote"

# Fetch source refs (heads + tags only). Hidden refs such as refs/pull/* are intentionally excluded.
git -C "$mirror" fetch --prune source \
  '+refs/heads/*:refs/heads/*' \
  '+refs/tags/*:refs/tags/*'

# Fetch destination refs into a separate namespace so we can enforce safe mirror rules.
git -C "$mirror" fetch --prune dest \
  '+refs/heads/*:refs/dest/heads/*' \
  '+refs/tags/*:refs/dest/tags/*'

declare -A src_heads=()
declare -a deleted_branches=()
declare -a rewritten_branches=()
declare -a rewritten_tags=()

while IFS= read -r branch; do
  [[ -n "$branch" ]] || continue
  src_heads["$branch"]=1
done < <(git -C "$mirror" for-each-ref --format='%(refname:lstrip=2)' refs/heads)

while IFS= read -r branch; do
  [[ -n "$branch" ]] || continue
  if [[ -z "${src_heads[$branch]+x}" ]]; then
    deleted_branches+=("$branch")
    continue
  fi

  src_sha=$(git -C "$mirror" rev-parse "refs/heads/$branch")
  dst_sha=$(git -C "$mirror" rev-parse "refs/dest/heads/$branch")
  if ! git -C "$mirror" merge-base --is-ancestor "$dst_sha" "$src_sha"; then
    rewritten_branches+=("$branch")
  fi
done < <(git -C "$mirror" for-each-ref --format='%(refname:lstrip=3)' refs/dest/heads)

while IFS= read -r tag; do
  [[ -n "$tag" ]] || continue
  if git -C "$mirror" show-ref --verify --quiet "refs/dest/tags/$tag"; then
    src_obj=$(git -C "$mirror" rev-parse "refs/tags/$tag^{object}")
    dst_obj=$(git -C "$mirror" rev-parse "refs/dest/tags/$tag^{object}")
    if [[ "$src_obj" != "$dst_obj" ]]; then
      rewritten_tags+=("$tag")
    fi
  fi
done < <(git -C "$mirror" for-each-ref --format='%(refname:lstrip=2)' refs/tags)

if (( ${#deleted_branches[@]} > MAX_PRUNE_DELETIONS )) && [[ "$ALLOW_FORCE_MIRROR" != "1" ]]; then
  echo "Refusing prune: ${#deleted_branches[@]} destination branches would be deleted (MAX_PRUNE_DELETIONS=${MAX_PRUNE_DELETIONS})." >&2
  printf 'Branches pending deletion:\n%s\n' "${deleted_branches[*]}" >&2
  echo "Set ALLOW_FORCE_MIRROR=1 for an explicit destructive reconciliation run." >&2
  exit 1
fi

if (( ${#rewritten_branches[@]} > 0 )) && [[ "$ALLOW_FORCE_MIRROR" != "1" ]]; then
  echo "Refusing non-fast-forward mirror for branches: ${rewritten_branches[*]}" >&2
  echo "Set ALLOW_FORCE_MIRROR=1 for an explicit destructive reconciliation run." >&2
  exit 1
fi

if (( ${#rewritten_tags[@]} > 0 )) && [[ "$ALLOW_FORCE_MIRROR" != "1" ]]; then
  echo "Refusing tag rewrite mirror for tags: ${rewritten_tags[*]}" >&2
  echo "Set ALLOW_FORCE_MIRROR=1 for an explicit destructive reconciliation run." >&2
  exit 1
fi

if [[ "$ALLOW_FORCE_MIRROR" == "1" ]]; then
  echo "ALLOW_FORCE_MIRROR=1 set: allowing branch/tag rewrites."
  git -C "$mirror" push --prune dest \
    '+refs/heads/*:refs/heads/*' \
    '+refs/tags/*:refs/tags/*'
else
  git -C "$mirror" push --prune dest \
    'refs/heads/*:refs/heads/*' \
    'refs/tags/*:refs/tags/*'
fi

echo "Mirror complete: ${SOURCE_REPO} -> ${DEST_REPO}"
