#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_REPO:?SOURCE_REPO is required (e.g. Spitfire-Cowboy/alcove-private)}"
: "${DEST_REPO:?DEST_REPO is required (e.g. Pro777/alcove-private)}"

MIRROR_MODE="${MIRROR_MODE:-direct}"
DEST_PUSH_MODE="${DEST_PUSH_MODE:-https}"
STRICT_PAIRING="${STRICT_PAIRING:-1}"
MAX_PRUNE_DELETIONS="${MAX_PRUNE_DELETIONS:-5}"
ALLOW_FORCE_MIRROR="${ALLOW_FORCE_MIRROR:-0}"
SOURCE_BRANCH="${SOURCE_BRANCH:-}"
DEST_BRANCH="${DEST_BRANCH:-}"
DEST_SYNC_BRANCH="${DEST_SYNC_BRANCH:-}"
DEST_API_TOKEN="${DEST_API_TOKEN:-}"

SOURCE_REMOTE_URL="${SOURCE_REMOTE_URL:-}"
DEST_REMOTE_URL="${DEST_REMOTE_URL:-}"

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

if [[ -z "$SOURCE_REMOTE_URL" ]]; then
  : "${SOURCE_TOKEN:?SOURCE_TOKEN is required}"
  source_remote="https://x-access-token:${SOURCE_TOKEN}@github.com/${SOURCE_REPO}.git"
else
  source_remote="$SOURCE_REMOTE_URL"
fi

if [[ -n "$DEST_REMOTE_URL" ]]; then
  dest_remote="$DEST_REMOTE_URL"
elif [[ "$DEST_PUSH_MODE" == "https" ]]; then
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

git -C "$mirror" remote add source "$source_remote"
git -C "$mirror" remote add dest "$dest_remote"

case "$MIRROR_MODE" in
  direct)
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
    ;;

  pull_request)
    : "${SOURCE_BRANCH:?SOURCE_BRANCH is required for pull_request mode}"
    : "${DEST_BRANCH:?DEST_BRANCH is required for pull_request mode}"
    : "${DEST_SYNC_BRANCH:?DEST_SYNC_BRANCH is required for pull_request mode}"
    : "${DEST_API_TOKEN:?DEST_API_TOKEN is required for pull_request mode}"

    git -C "$mirror" fetch --prune source \
      "+refs/heads/${SOURCE_BRANCH}:refs/heads/${SOURCE_BRANCH}"
    git -C "$mirror" fetch --prune dest \
      "+refs/heads/${DEST_BRANCH}:refs/dest/heads/${DEST_BRANCH}"

    if git ls-remote --exit-code --heads "$dest_remote" "$DEST_SYNC_BRANCH" >/dev/null 2>&1; then
      git -C "$mirror" fetch --prune dest \
        "+refs/heads/${DEST_SYNC_BRANCH}:refs/dest/heads/${DEST_SYNC_BRANCH}"
    fi

    src_sha="$(git -C "$mirror" rev-parse "refs/heads/${SOURCE_BRANCH}")"
    dst_sha="$(git -C "$mirror" rev-parse "refs/dest/heads/${DEST_BRANCH}")"

    pr_title="Mirror sync: ${SOURCE_REPO} ${SOURCE_BRANCH} -> ${DEST_BRANCH}"
    pr_body_file="$tmp_dir/pr-body.md"
    cat > "$pr_body_file" <<EOF
Automated mirror sync for \`${SOURCE_REPO}\`.

- Source branch: \`${SOURCE_BRANCH}\` @ \`${src_sha}\`
- Destination base: \`${DEST_BRANCH}\`
- Sync branch: \`${DEST_SYNC_BRANCH}\`

This PR exists because \`${DEST_REPO}:${DEST_BRANCH}\` requires PR-based updates.
EOF

    pr_query=(
      gh pr list
      --repo "$DEST_REPO"
      --state open
      --head "$DEST_SYNC_BRANCH"
      --base "$DEST_BRANCH"
      --json number,headRefOid,url
    )

    pr_number="$(GH_TOKEN="$DEST_API_TOKEN" "${pr_query[@]}" --jq '.[0].number // ""')"
    pr_head_sha="$(GH_TOKEN="$DEST_API_TOKEN" "${pr_query[@]}" --jq '.[0].headRefOid // ""')"

    if [[ "$src_sha" == "$dst_sha" ]]; then
      echo "Destination base already matches source: ${DEST_REPO}:${DEST_BRANCH} @ ${dst_sha}"
      if [[ -n "$pr_number" ]]; then
        GH_TOKEN="$DEST_API_TOKEN" gh pr close "$pr_number" \
          --repo "$DEST_REPO" \
          --comment "Closing automated mirror PR because \`${DEST_BRANCH}\` already matches \`${SOURCE_REPO}:${SOURCE_BRANCH}\` @ \`${src_sha}\`."
      fi
      exit 0
    fi

    git -C "$mirror" push --force-with-lease dest \
      "refs/heads/${SOURCE_BRANCH}:refs/heads/${DEST_SYNC_BRANCH}"

    if [[ -z "$pr_number" ]]; then
      GH_TOKEN="$DEST_API_TOKEN" gh pr create \
        --repo "$DEST_REPO" \
        --base "$DEST_BRANCH" \
        --head "$DEST_SYNC_BRANCH" \
        --title "$pr_title" \
        --body-file "$pr_body_file"
      echo "Opened PR-based mirror sync: ${SOURCE_REPO}:${SOURCE_BRANCH} -> ${DEST_REPO}:${DEST_BRANCH} via ${DEST_SYNC_BRANCH}"
    else
      if [[ "$pr_head_sha" != "$src_sha" ]]; then
        echo "Updated existing PR #${pr_number} head from ${pr_head_sha:-unknown} to ${src_sha}"
      fi
      GH_TOKEN="$DEST_API_TOKEN" gh pr edit "$pr_number" \
        --repo "$DEST_REPO" \
        --title "$pr_title" \
        --body-file "$pr_body_file"
      echo "Updated PR-based mirror sync: ${SOURCE_REPO}:${SOURCE_BRANCH} -> ${DEST_REPO}:${DEST_BRANCH} via ${DEST_SYNC_BRANCH}"
    fi
    ;;

  *)
    echo "Unsupported MIRROR_MODE: $MIRROR_MODE" >&2
    exit 1
    ;;
esac
