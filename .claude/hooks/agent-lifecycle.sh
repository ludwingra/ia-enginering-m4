#!/usr/bin/env bash
# ASD SDK v3.17.0 — Agent Lifecycle Hook
# Captura SubagentStart y SubagentStop → events.jsonl
# Manages agent-pool.json (increment on start, decrement on stop) with portable locking
# Uso: .claude/hooks/agent-lifecycle.sh (recibe evento como argumento implícito en stdin)

set -euo pipefail

OBS_DIR=".claude/observability"
POOL_FILE="$OBS_DIR/agent-pool.json"
LOCK_DIR="$OBS_DIR/agent-pool.lock.d"
SETTINGS_FILE=".claude/settings.json"

mkdir -p "$OBS_DIR"

INPUT=$(cat)

# ─── Portable lock helpers ────────────────────────────────────────────────
_lock_acquired=0

acquire_lock() {
  local max_wait=4
  local waited=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 0.1
    waited=$(( waited + 1 ))
    if [ "$waited" -ge $(( max_wait * 10 )) ]; then
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

# ─── Graceful fallback: if jq not available, log raw and skip pool ────────
if ! command -v jq &>/dev/null; then
  EVENTS_FILE="$OBS_DIR/events.jsonl"
  RAW_ESCAPED=$(echo "$INPUT" | head -c 500 | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g')
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"agent_event\",\"raw\":\"$RAW_ESCAPED\"}" >> "$EVENTS_FILE"
  exit 0
fi

EVENT_NAME=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Per-session event storage
EVENTS_DIR="$OBS_DIR/events"
mkdir -p "$EVENTS_DIR"
EVENTS_FILE="$EVENTS_DIR/${SESSION_ID}.jsonl"
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')

case "$EVENT_NAME" in
  SubagentStart)
    EVENT_TYPE="agent_start"
    ;;
  SubagentStop)
    EVENT_TYPE="agent_stop"
    ;;
  *)
    EVENT_TYPE="agent_event"
    ;;
esac

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "{\"ts\":\"$TS\",\"event\":\"$EVENT_TYPE\",\"session\":\"$SESSION_ID\",\"agent\":\"$AGENT_TYPE\",\"agent_id\":\"$AGENT_ID\"}" >> "$EVENTS_FILE"

# ─── Pool Management ──────────────────────────────────────────────────────
# Read max_concurrent from settings or default
DEFAULT_MAX=6
MAX_CONCURRENT=""
if [ -f "$SETTINGS_FILE" ]; then
  MAX_CONCURRENT=$(jq -r '.orchestration.max_parallel_agents // empty' "$SETTINGS_FILE" 2>/dev/null || echo "")
fi
MAX_CONCURRENT="${MAX_CONCURRENT:-$DEFAULT_MAX}"

# Initialize or sync pool file
if [ ! -f "$POOL_FILE" ]; then
  echo "{\"max_concurrent\":$MAX_CONCURRENT,\"active\":[],\"active_count\":0}" > "$POOL_FILE"
else
  # Sync max_concurrent from settings on every check (fixes stale value after config change)
  CURRENT_MAX=$(jq -r '.max_concurrent // 0' "$POOL_FILE" 2>/dev/null || echo "0")
  if [ "$CURRENT_MAX" != "$MAX_CONCURRENT" ]; then
    jq --argjson max "$MAX_CONCURRENT" '.max_concurrent = $max' "$POOL_FILE" > "$POOL_FILE.tmp" && mv "$POOL_FILE.tmp" "$POOL_FILE"
  fi
fi

# Atomic pool update
acquire_lock

POOL=$(cat "$POOL_FILE")

case "$EVENT_NAME" in
  SubagentStart)
    # Add agent to pool
    POOL=$(echo "$POOL" | jq \
      --arg id "$AGENT_ID" \
      --arg type "$AGENT_TYPE" \
      --arg ts "$TS" \
      '.active += [{"agent_id": $id, "type": $type, "started_at": $ts}] |
       .active_count = (.active | length)')
    echo "$POOL" > "$POOL_FILE"

    ACTIVE_COUNT=$(echo "$POOL" | jq -r '.active_count')
    echo "{\"ts\":\"$TS\",\"event\":\"pool_increment\",\"agent_id\":\"$AGENT_ID\",\"agent_type\":\"$AGENT_TYPE\",\"active_count\":$ACTIVE_COUNT}" >> "$EVENTS_FILE"
    ;;

  SubagentStop)
    # Remove agent from pool
    POOL=$(echo "$POOL" | jq \
      --arg id "$AGENT_ID" \
      '.active |= [.[] | select(.agent_id != $id)] |
       .active_count = (.active | length)')
    echo "$POOL" > "$POOL_FILE"

    ACTIVE_COUNT=$(echo "$POOL" | jq -r '.active_count')
    echo "{\"ts\":\"$TS\",\"event\":\"pool_decrement\",\"agent_id\":\"$AGENT_ID\",\"agent_type\":\"$AGENT_TYPE\",\"active_count\":$ACTIVE_COUNT}" >> "$EVENTS_FILE"
    ;;
esac

release_lock

exit 0
