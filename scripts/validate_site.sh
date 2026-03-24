#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SITE_DIR="$ROOT_DIR/site"

required=(
  "$SITE_DIR/index.html"
  "$SITE_DIR/robots.txt"
  "$SITE_DIR/sitemap.xml"
  "$SITE_DIR/llms.txt"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
done

if ! grep -Eq '^Sitemap: https://alcove\.software/sitemap\.xml$' "$SITE_DIR/robots.txt"; then
  echo "robots.txt must include canonical sitemap URL" >&2
  exit 1
fi

if ! grep -Eq '<loc>https://alcove\.software/</loc>' "$SITE_DIR/sitemap.xml"; then
  echo "sitemap.xml missing root URL" >&2
  exit 1
fi

if ! grep -Eq 'https://github.com/Pro777/alcove' "$SITE_DIR/llms.txt"; then
  echo "llms.txt missing canonical codebase URL" >&2
  exit 1
fi

echo "site validation passed"
