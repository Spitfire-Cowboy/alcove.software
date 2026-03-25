#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-alcove.software}"
PAGES_REPO="${PAGES_REPO:-Spitfire-Cowboy/alcove.software}"

failures=0

ok() {
  echo "OK: $1"
}

fail() {
  echo "FAIL: $1" >&2
  failures=$((failures + 1))
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

resolve_domain() {
  local domain="$1"
  python3 - "$domain" <<'PY'
import socket
import sys

domain = sys.argv[1]
try:
    info = socket.getaddrinfo(domain, 443, proto=socket.IPPROTO_TCP)
except socket.gaierror:
    sys.exit(1)

ips = sorted({row[4][0] for row in info})
for ip in ips:
    print(ip)
PY
}

check_https_path() {
  local path="$1"
  local url="https://${DOMAIN}${path}"
  local result http_code final_url
  if ! result="$(curl -sS -L -o /dev/null -w '%{http_code} %{url_effective}' --max-time 20 "$url" 2>&1)"; then
    fail "${url} request failed (${result})"
    return
  fi
  http_code="${result%% *}"
  final_url="${result#* }"
  if [[ "$http_code" == "200" && "$final_url" == "https://${DOMAIN}"* ]]; then
    ok "${url} -> ${http_code} (${final_url})"
  else
    fail "${url} expected 200 on https://${DOMAIN}*, got ${http_code} (${final_url})"
  fi
}

check_http_redirect() {
  local url="http://${DOMAIN}/"
  local result http_code final_url
  if ! result="$(curl -sS -L -o /dev/null -w '%{http_code} %{url_effective}' --max-time 20 "$url" 2>&1)"; then
    fail "${url} request failed (${result})"
    return
  fi
  http_code="${result%% *}"
  final_url="${result#* }"
  if [[ "$http_code" == "200" && "$final_url" == "https://${DOMAIN}"* ]]; then
    ok "${url} redirects to HTTPS (${final_url})"
  else
    fail "${url} expected HTTPS redirect ending in 200, got ${http_code} (${final_url})"
  fi
}

check_pages_settings() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "INFO: gh not found, skipping Pages API check."
    return
  fi

  local pages
  if ! pages="$(gh api "repos/${PAGES_REPO}/pages" --jq '{cname: .cname, https_enforced: .https_enforced, source: .source}' 2>/dev/null)"; then
    echo "INFO: unable to read Pages API for ${PAGES_REPO} (missing token or permissions)."
    return
  fi

  echo "Pages API: ${pages}"
}

require_cmd curl
require_cmd python3

echo "Cutover verification target: ${DOMAIN}"
echo

addresses="$(resolve_domain "$DOMAIN" || true)"
if [[ -z "$addresses" ]]; then
  fail "domain does not resolve (${DOMAIN})"
else
  ok "domain resolves (${DOMAIN})"
  echo "Resolved addresses:"
  echo "$addresses"
fi

check_https_path "/"
check_https_path "/robots.txt"
check_https_path "/sitemap.xml"
check_https_path "/llms.txt"
check_http_redirect
check_pages_settings

echo
if (( failures > 0 )); then
  echo "Cutover verification failed (${failures} checks)." >&2
  exit 1
fi

echo "Cutover verification passed."
