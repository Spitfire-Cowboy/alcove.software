#!/usr/bin/env bash
set -euo pipefail

MAX_ATTEMPTS="${GH_API_MAX_ATTEMPTS:-5}"
BASE_DELAY_SEC="${GH_API_BASE_DELAY_SEC:-2}"
MAX_DELAY_SEC="${GH_API_MAX_DELAY_SEC:-60}"

if ! [[ "$MAX_ATTEMPTS" =~ ^[0-9]+$ ]] || (( MAX_ATTEMPTS < 1 )); then
  echo "GH_API_MAX_ATTEMPTS must be an integer >= 1" >&2
  exit 1
fi

if ! [[ "$BASE_DELAY_SEC" =~ ^[0-9]+$ ]] || (( BASE_DELAY_SEC < 1 )); then
  echo "GH_API_BASE_DELAY_SEC must be an integer >= 1" >&2
  exit 1
fi

if ! [[ "$MAX_DELAY_SEC" =~ ^[0-9]+$ ]] || (( MAX_DELAY_SEC < 1 )); then
  echo "GH_API_MAX_DELAY_SEC must be an integer >= 1" >&2
  exit 1
fi

is_retryable_error() {
  local output="$1"
  [[ "$output" == *"rate limit exceeded"* ]] && return 0
  [[ "$output" == *"secondary rate limit"* ]] && return 0
  [[ "$output" == *"HTTP 429"* ]] && return 0
  [[ "$output" == *"HTTP 502"* ]] && return 0
  [[ "$output" == *"HTTP 503"* ]] && return 0
  [[ "$output" == *"HTTP 504"* ]] && return 0
  return 1
}

attempt=1
while (( attempt <= MAX_ATTEMPTS )); do
  set +e
  output="$(gh api "$@" 2>&1)"
  rc=$?
  set -e

  if (( rc == 0 )); then
    printf '%s\n' "$output"
    exit 0
  fi

  if (( attempt == MAX_ATTEMPTS )) || ! is_retryable_error "$output"; then
    printf '%s\n' "$output" >&2
    exit "$rc"
  fi

  delay=$(( BASE_DELAY_SEC * (2 ** (attempt - 1)) ))
  if (( delay > MAX_DELAY_SEC )); then
    delay="$MAX_DELAY_SEC"
  fi

  # Small jitter prevents synchronized retries across parallel jobs.
  jitter_ms=$(( RANDOM % 700 ))
  sleep_for="$(awk -v d="$delay" -v j="$jitter_ms" 'BEGIN{printf "%.3f", d + (j/1000)}')"
  echo "gh api retry ${attempt}/${MAX_ATTEMPTS} in ${sleep_for}s" >&2
  sleep "$sleep_for"
  attempt=$((attempt + 1))
done
