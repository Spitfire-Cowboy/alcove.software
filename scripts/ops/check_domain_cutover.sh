#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-alcove.software}"
PAGES_REPO="${PAGES_REPO:-Spitfire-Cowboy/alcove.software}"
EXPECTED_CNAME="${EXPECTED_CNAME:-$DOMAIN}"
EXPECTED_PUBLIC="${EXPECTED_PUBLIC:-true}"
EXPECTED_HTTPS_ENFORCED="${EXPECTED_HTTPS_ENFORCED:-true}"

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

json_field() {
  local expr="$1"
  python3 -c '''
import json
import sys

obj = json.load(sys.stdin)
cur = obj
for part in sys.argv[1].split("."):
    if isinstance(cur, dict):
        cur = cur.get(part)
    else:
        cur = None
        break

if cur is None:
    print("")
elif isinstance(cur, bool):
    print(str(cur).lower())
else:
    print(cur)
''' "$expr"
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
  if ! pages="$(gh api "repos/${PAGES_REPO}/pages" 2>/dev/null)"; then
    echo "INFO: unable to read Pages API for ${PAGES_REPO} (missing token or permissions)."
    return
  fi

  local actual_cname actual_public actual_https cert_state cert_desc build_type
  actual_cname="$(printf '%s' "$pages" | json_field cname)"
  actual_public="$(printf '%s' "$pages" | json_field public)"
  actual_https="$(printf '%s' "$pages" | json_field https_enforced)"
  cert_state="$(printf '%s' "$pages" | json_field https_certificate.state)"
  cert_desc="$(printf '%s' "$pages" | json_field https_certificate.description)"
  build_type="$(printf '%s' "$pages" | json_field build_type)"

  echo "Pages API: $(printf '%s' "$pages" | python3 -c 'import json,sys; obj=json.load(sys.stdin); print(json.dumps({"cname":obj.get("cname"),"public":obj.get("public"),"https_enforced":obj.get("https_enforced"),"build_type":obj.get("build_type"),"https_certificate":obj.get("https_certificate")}, separators=(",",":")))')"

  if [[ "$actual_cname" == "$EXPECTED_CNAME" ]]; then
    ok "Pages custom domain is ${EXPECTED_CNAME}"
  else
    fail "Pages custom domain expected ${EXPECTED_CNAME}, got ${actual_cname:-<empty>}"
  fi

  if [[ "$actual_public" == "$EXPECTED_PUBLIC" ]]; then
    ok "Pages visibility is ${EXPECTED_PUBLIC}"
  else
    fail "Pages visibility expected ${EXPECTED_PUBLIC}, got ${actual_public:-<empty>}"
  fi

  if [[ "$actual_https" == "$EXPECTED_HTTPS_ENFORCED" ]]; then
    ok "Pages HTTPS enforcement is ${EXPECTED_HTTPS_ENFORCED}"
  else
    fail "Pages HTTPS enforcement expected ${EXPECTED_HTTPS_ENFORCED}, got ${actual_https:-<empty>}"
  fi

  if [[ "$build_type" == "workflow" ]]; then
    ok "Pages build type is workflow"
  else
    fail "Pages build type expected workflow, got ${build_type:-<empty>}"
  fi

  if [[ "$cert_state" == "approved" ]]; then
    ok "Pages certificate is approved"
  else
    fail "Pages certificate expected approved, got ${cert_state:-<empty>} (${cert_desc:-no description})"
  fi
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
