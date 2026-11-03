#!/usr/bin/env bash
# Sends one ping to Heartcron. Inputs come from action.yml as HC_* variables.
set -uo pipefail

warn() {
  if [ "${HC_STRICT:-false}" = "true" ]; then
    echo "::error::$1"
    exit 1
  fi
  echo "::warning::$1"
  exit 0
}

url="${HC_URL:-}"
if [ -z "$url" ]; then
  if [ -z "${HC_PING_KEY:-}" ] || [ -z "${HC_SLUG:-}" ]; then
    warn "Heartcron: set url, or ping-key and slug"
  fi
  url="${HC_BASE%/}/${HC_PING_KEY}/${HC_SLUG}"
fi
case "$url" in
  https://*|http://*) ;;
  *) warn "Heartcron: url must start with https://" ;;
esac
url="${url%/}"

# the job status names GitHub uses map onto Heartcron signals
case "${HC_STATUS:-success}" in
  ""|success|ok|0) suffix="" ;;
  start|started) suffix="/start" ;;
  fail|failure|failed|cancelled|canceled) suffix="/fail" ;;
  log) suffix="/log" ;;
  *)
    if [[ "$HC_STATUS" =~ ^[0-9]+$ ]] && [ "$HC_STATUS" -le 255 ]; then
      suffix="/$HC_STATUS"
    else
      warn "Heartcron: unknown status \"$HC_STATUS\""
    fi
    ;;
esac
url="$url$suffix"
if [ "${HC_CREATE:-false}" = "true" ] && [ -z "${HC_URL:-}" ]; then
  url="$url?create=1"
fi

args=(-fsS -m 10 --retry 3 -o /dev/null -A "heartcron-ping-action/1")
if [ -n "${HC_BODY:-}" ]; then
  if ! printf '%s' "$HC_BODY" | curl "${args[@]}" --data-binary @- "$url"; then
    warn "Heartcron: the ping didn't go through"
  fi
elif ! curl "${args[@]}" "$url"; then
  warn "Heartcron: the ping didn't go through"
fi
echo "Heartcron: sent ${HC_STATUS:-success}"
