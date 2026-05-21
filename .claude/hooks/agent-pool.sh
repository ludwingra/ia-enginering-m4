#!/usr/bin/env bash
# ASD SDK v3.17.0 — Agent Pool Semaphore Hook (PreToolUse matcher: Agent)
# Enforces max concurrent agent limit. CAN BLOCK dispatch if pool is at capacity.
#
# Behavior:
#   - active_count < max → allow silently (exit 0)
#   - active_count >= max → block with JSON reason
#   - Cleans stale agents (TTL > 30 min) on each check
#   - Uses portable locking (flock when available, mkdir fallback) for atomic R/W
#
# Coexists with pre-agent-dispatch.sh (which only advises, never blocks).

set -euo pipefail

OBS_DIR=".claude/observability"
POOL_FILE="$OBS_DIR/agent-pool.json"
LOCK_DIR="$OBS_DIR/agent-pool.lock.d"
SETTINGS_FILE=".claude/settings.json"
EVENTS_FILE="$OBS_DIR/events.jsonl"

mkdir -p "$OBS_DIR"

# ─── Portable lock helpers ────────────────────────────────────────────────
_lock_acquired=0

acquire_lock() {
  local max_wait=4
  local waited=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 0.1
    waited=$(( waited + 1 ))
    if [ "$waited" -ge $(( max_wait * 10 )) ]; then
      # Stale lock — force remove and retry once
      rm -rf "$LOCK_DIR"
      mkdir "$LOCK_DIR" 2>/dev/null || true
      break
    fi
  done
  _lock_acquired=1
}

release_lock() {
  if [ "$_lock_acquired" -eq 1 ]; then
    rm -rf "$LOCK_DIR"
    _lock_acquired=0
  fi
}

trap release_lock EXIT

# ─── Graceful fallback: if jq not available, allow silently ───────────────
if ! command -v jq &>/dev/null; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$TS\",\"event\":\"pool_check\",\"status\":\"skipped\",\"reason\":\"jq_not_available\"}" >> "$EVENTS_FILE"
  exit 0
fi

# ─── Read max_concurrent from settings or default ─────────────────────────
# Capacity levels: min=2, max=6 (configurable via settings.json)
# Configured via settings.json:orchestration.{min,max}_parallel_agents
DEFAULT_MAX=6
DEFAULT_MIN=2
MAX_CONCURRENT=""
MIN_CONCURRENT=""
if [ -f "$SETTINGS_FILE" ]; then
  MAX_CONCURRENT=$(jq -r '.orchestration.max_parallel_agents // empty' "$SETTINGS_FILE" 2>/dev/null || echo "")
  MIN_CONCURRENT=$(jq -r '.orchestration.min_parallel_agents // empty' "$SETTINGS_FILE" 2>/dev/null || echo "")
fi
MAX_CONCURRENT="${MAX_CONCURRENT:-$DEFAULT_MAX}"
MIN_CONCURRENT="${MIN_CONCURRENT:-$DEFAULT_MIN}"

# ─── Initialize or sync pool file ────────────────────────────────────────
if [ ! -f "$POOL_FILE" ]; then
  echo "{\"max_concurrent\":$MAX_CONCURRENT,\"active\":[],\"active_count\":0}" > "$POOL_FILE"
else
  # Sync max_concurrent from settings on every check (fixes stale value after config change)
  CURRENT_MAX=$(jq -r '.max_concurrent // 0' "$POOL_FILE" 2>/dev/null || echo "0")
  if [ "$CURRENT_MAX" != "$MAX_CONCURRENT" ]; then
    jq --argjson max "$MAX_CONCURRENT" '.max_concurrent = $max' "$POOL_FILE" > "$POOL_FILE.tmp" && mv "$POOL_FILE.tmp" "$POOL_FILE"
  fi
fi

# ─── Atomic read + TTL cleanup + capacity check ──────────────────────────
DECISION="allow"
REASON=""

acquire_lock

# Read current pool state
POOL=$(cat "$POOL_FILE")

# TTL cleanup: remove agents with started_at > 30 minutes ago
NOW_EPOCH=$(date +%s)
TTL_SECONDS=1800  # 30 minutes

CLEANED_POOL=$(echo "$POOL" | jq --argjson now "$NOW_EPOCH" --argjson ttl "$TTL_SECONDS" '
  .active as $before |
  .active |= [.[] | select(
    ((.started_at | sub("\\.[0-9]+Z$"; "Z") | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) + $ttl) > $now
  )] |
  .active_count = (.active | length) |
  . + { "_stale_removed": (($before | length) - (.active | length)) }
')

STALE_REMOVED=$(echo "$CLEANED_POOL" | jq -r '._stale_removed // 0')
CLEANED_POOL=$(echo "$CLEANED_POOL" | jq 'del(._stale_removed)')

# Log TTL cleanup if agents were removed
if [ "$STALE_REMOVED" -gt 0 ] 2>/dev/null; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$TS\",\"event\":\"pool_ttl_cleanup\",\"stale_removed\":$STALE_REMOVED}" >> "$EVENTS_FILE"
fi

# Write cleaned pool back
echo "$CLEANED_POOL" > "$POOL_FILE"

# Check capacity
ACTIVE_COUNT=$(echo "$CLEANED_POOL" | jq -r '.active_count')

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [ "$ACTIVE_COUNT" -ge "$MAX_CONCURRENT" ]; then
  DECISION="block"
  REASON="Agent pool at capacity ($ACTIVE_COUNT/$MAX_CONCURRENT). Wait for a running agent to complete before dispatching another."
  echo "{\"ts\":\"$TS\",\"event\":\"pool_deny\",\"active_count\":$ACTIVE_COUNT,\"max_concurrent\":$MAX_CONCURRENT}" >> "$EVENTS_FILE"
else
  echo "{\"ts\":\"$TS\",\"event\":\"pool_check\",\"status\":\"allowed\",\"active_count\":$ACTIVE_COUNT,\"max_concurrent\":$MAX_CONCURRENT}" >> "$EVENTS_FILE"
fi

release_lock

# ─── Output decision ──────────────────────────────────────────────────────
if [ "$DECISION" = "block" ]; then
  REASON_JSON=$(echo "$REASON" | jq -Rs .)
  cat <<HOOK_OUTPUT
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $REASON_JSON
  }
}
HOOK_OUTPUT
fi

exit 0
