#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SITE_DIR="$ROOT_DIR/site"

required=(
  "$SITE_DIR/index.html"
  "$SITE_DIR/docs/index.html"
  "$SITE_DIR/federation/nodes.sample.json"
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

if ! grep -Eq '^User-agent: Googlebot$' "$SITE_DIR/robots.txt"; then
  echo "robots.txt missing Googlebot policy stanza" >&2
  exit 1
fi

if ! grep -Eq '^User-agent: Bingbot$' "$SITE_DIR/robots.txt"; then
  echo "robots.txt missing Bingbot policy stanza" >&2
  exit 1
fi

if ! grep -Eq '<loc>https://alcove\.software/</loc>' "$SITE_DIR/sitemap.xml"; then
  echo "sitemap.xml missing root URL" >&2
  exit 1
fi

if ! grep -Eq '<loc>https://alcove\.software/llms\.txt</loc>' "$SITE_DIR/sitemap.xml"; then
  echo "sitemap.xml missing llms manifest URL" >&2
  exit 1
fi

if ! grep -Eq '<loc>https://alcove\.software/docs/</loc>' "$SITE_DIR/sitemap.xml"; then
  echo "sitemap.xml missing docs landing URL" >&2
  exit 1
fi

if ! grep -Eq '<loc>https://alcove\.software/federation/nodes\.sample\.json</loc>' "$SITE_DIR/sitemap.xml"; then
  echo "sitemap.xml missing federation sample registry URL" >&2
  exit 1
fi

if ! grep -Eq 'https://github.com/Spitfire-Cowboy/alcove' "$SITE_DIR/llms.txt"; then
  echo "llms.txt missing canonical codebase URL" >&2
  exit 1
fi

if ! grep -Eq '<meta name="robots" content="index,follow' "$SITE_DIR/index.html"; then
  echo "index.html missing index/follow robots meta" >&2
  exit 1
fi

if ! grep -Eq '<link rel="canonical" href="https://alcove\.software/">' "$SITE_DIR/index.html"; then
  echo "index.html missing canonical URL tag" >&2
  exit 1
fi

jq -e 'type == "array" and length >= 1' "$SITE_DIR/federation/nodes.sample.json" >/dev/null
jq -e 'map(.node_id) | length == (unique | length)' "$SITE_DIR/federation/nodes.sample.json" >/dev/null

echo "site validation passed"
