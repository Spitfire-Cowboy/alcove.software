#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SITE_DIR="$ROOT_DIR/site"

required=(
  "$SITE_DIR/index.html"
  "$SITE_DIR/assets/tailwind.css"
  "$SITE_DIR/docs/index.html"
  "$SITE_DIR/library/index.html"
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
  "$SITE_DIR/assets/alcove-lp-queue.png"
  "$SITE_DIR/assets/alcove-lp-now-playing.png"
  "$SITE_DIR/assets/alcove-lp-my-library.png"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
done

shared_navigation_pages=(
  "$SITE_DIR/index.html"
  "$SITE_DIR/home/index.html"
  "$SITE_DIR/business/index.html"
  "$SITE_DIR/library/index.html"
  "$SITE_DIR/docs/index.html"
  "$SITE_DIR/lp/index.html"
  "$SITE_DIR/lp/support/index.html"
  "$SITE_DIR/lp/privacy/index.html"
)

for file in "${shared_navigation_pages[@]}"; do
  if ! grep -Fq 'href="/assets/tailwind.css"' "$file"; then
    echo "Shared site page missing compiled Tailwind CSS: $file" >&2
    exit 1
  fi
  if ! grep -Fq 'class="global-header"' "$file"; then
    echo "Shared site page missing the global header: $file" >&2
    exit 1
  fi
  if ! grep -Fq 'class="global-footer"' "$file"; then
    echo "Shared site page missing the global footer: $file" >&2
    exit 1
  fi
  for href in '/home/' '/business/' '/library/' '/lp/' '/docs/' 'https://congress.alcove.software/'; do
    if ! grep -Fq "href=\"$href\"" "$file"; then
      echo "Shared site navigation missing $href: $file" >&2
      exit 1
    fi
  done
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

if grep -Fq '<style>' "$SITE_DIR/docs/index.html"; then
  echo "Docs page must use the shared Tailwind stylesheet instead of inline CSS" >&2
  exit 1
fi

if ! grep -Fq 'class="docs-page"' "$SITE_DIR/docs/index.html"; then
  echo "Docs page missing its Tailwind page shell" >&2
  exit 1
fi

if ! grep -Eq '<loc>https://alcove\.software/library/</loc>' "$SITE_DIR/sitemap.xml"; then
  echo "sitemap.xml missing open-source library URL" >&2
  exit 1
fi

if ! grep -Fq '<meta http-equiv="refresh" content="0; url=/library/">' "$SITE_DIR/government/index.html"; then
  echo "legacy government route must redirect to the open-source library" >&2
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

if ! grep -Fq 'id="featured-work"' "$SITE_DIR/index.html"; then
  echo "index.html missing the featured work section" >&2
  exit 1
fi

for project in 'Alcove Congress' 'Alcove LP' 'Alcove Los Angeles'; do
  if ! grep -Fq "$project" "$SITE_DIR/index.html"; then
    echo "index.html featured work missing $project" >&2
    exit 1
  fi
done

for route in '' 'support/' 'privacy/'; do
  file="$SITE_DIR/lp/${route}index.html"
  if ! grep -Fq "<link rel=\"canonical\" href=\"https://alcove.software/lp/${route}\">" "$file"; then
    echo "Alcove LP page missing canonical URL: $file" >&2
    exit 1
  fi
  if grep -Fq 'analytics.spitfirecowboy.com' "$file"; then
    echo "Alcove LP pages must remain analytics-free: $file" >&2
    exit 1
  fi
done

if grep -Riq 'testflight' "$SITE_DIR/lp"; then
  echo "Alcove LP pages must not mention or link to TestFlight" >&2
  exit 1
fi

if grep -Riq 'https://lp.alcove.software' "$SITE_DIR"; then
  echo "Site content must use the canonical Alcove LP path URL" >&2
  exit 1
fi

if ! grep -Fq 'Sitemap: https://alcove.software/sitemap.xml' "$SITE_DIR/lp/robots.txt"; then
  echo "Alcove LP robots.txt missing canonical sitemap URL" >&2
  exit 1
fi

for route in '' 'support/' 'privacy/'; do
  if ! grep -Fq "<loc>https://alcove.software/lp/${route}</loc>" "$SITE_DIR/lp/sitemap.xml"; then
    echo "Alcove LP sitemap missing route: /${route}" >&2
    exit 1
  fi
done

jq -e 'type == "array" and length >= 1' "$SITE_DIR/federation/nodes.sample.json" >/dev/null
jq -e 'map(.node_id) | length == (unique | length)' "$SITE_DIR/federation/nodes.sample.json" >/dev/null

echo "site validation passed"
