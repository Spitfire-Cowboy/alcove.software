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
  "$SITE_DIR/lp/index.html"
  "$SITE_DIR/lp/support/index.html"
  "$SITE_DIR/lp/privacy/index.html"
  "$SITE_DIR/lp/robots.txt"
  "$SITE_DIR/lp/sitemap.xml"
  "$SITE_DIR/assets/lp.css"
  "$SITE_DIR/assets/alcove-lp-demo.png"
  "$SITE_DIR/assets/alcove-lp-shelf.png"
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

for route in '' 'support/' 'privacy/'; do
  file="$SITE_DIR/lp/${route}index.html"
  if ! grep -Fq "<link rel=\"canonical\" href=\"https://lp.alcove.software/${route}\">" "$file"; then
    echo "Alcove LP page missing canonical URL: $file" >&2
    exit 1
  fi
  if grep -Fq 'analytics.spitfirecowboy.com' "$file"; then
    echo "Alcove LP pages must remain analytics-free: $file" >&2
    exit 1
  fi
done

if ! grep -Fq 'Sitemap: https://lp.alcove.software/sitemap.xml' "$SITE_DIR/lp/robots.txt"; then
  echo "Alcove LP robots.txt missing canonical sitemap URL" >&2
  exit 1
fi

for route in '' 'support/' 'privacy/'; do
  if ! grep -Fq "<loc>https://lp.alcove.software/${route}</loc>" "$SITE_DIR/lp/sitemap.xml"; then
    echo "Alcove LP sitemap missing route: /${route}" >&2
    exit 1
  fi
done

jq -e 'type == "array" and length >= 1' "$SITE_DIR/federation/nodes.sample.json" >/dev/null
jq -e 'map(.node_id) | length == (unique | length)' "$SITE_DIR/federation/nodes.sample.json" >/dev/null

echo "site validation passed"
