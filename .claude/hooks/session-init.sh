#!/usr/bin/env bash
# ASD SDK v3.17.0 — Session Init Hook
# Captura SessionStart → events.jsonl + actualiza SESSION_CONTEXT.json
# Se ejecuta al inicio de cada sesión de Claude Code.

set -euo pipefail

OBS_DIR=".claude/observability"

mkdir -p "$OBS_DIR"

INPUT=$(cat)

if ! command -v jq &>/dev/null; then
  EVENTS_FILE="$OBS_DIR/events.jsonl"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"session_start\"}" >> "$EVENTS_FILE"
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Per-session event storage
EVENTS_DIR="$OBS_DIR/events"
mkdir -p "$EVENTS_DIR"
EVENTS_FILE="$EVENTS_DIR/${SESSION_ID}.jsonl"
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode // "default"')

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Escribir evento de inicio de sesión
echo "{\"ts\":\"$TS\",\"event\":\"session_start\",\"session\":\"$SESSION_ID\",\"cwd\":\"$CWD\",\"permission_mode\":\"$PERMISSION_MODE\"}" >> "$EVENTS_FILE"

# Actualizar SESSION_CONTEXT.json si existe
SESSION_CTX_FILE=".claude/SESSION_CONTEXT.json"
if [ -f "$SESSION_CTX_FILE" ] && command -v jq &>/dev/null; then
  UPDATED=$(jq --arg sid "$SESSION_ID" --arg ts "$TS" \
    '.session_id = $sid | .initialized_at = $ts' "$SESSION_CTX_FILE" 2>/dev/null) || true
  if [ -n "$UPDATED" ]; then
    echo "$UPDATED" > "$SESSION_CTX_FILE"
  fi
fi

# Update sessions.json index
SESSIONS_INDEX="$OBS_DIR/sessions.json"
if [ -f "$SESSIONS_INDEX" ] && command -v jq &>/dev/null; then
  jq --arg sid "$SESSION_ID" --arg ts "$TS" \
    '. + [{"sessionId": $sid, "firstEvent": $ts, "lastEvent": $ts, "eventCount": 1, "hasEnded": false, "hasSummary": false}]' \
    "$SESSIONS_INDEX" > "${SESSIONS_INDEX}.tmp" && mv "${SESSIONS_INDEX}.tmp" "$SESSIONS_INDEX"
else
  echo "[{\"sessionId\":\"$SESSION_ID\",\"firstEvent\":\"$TS\",\"lastEvent\":\"$TS\",\"eventCount\":1,\"hasEnded\":false,\"hasSummary\":false}]" > "$SESSIONS_INDEX"
fi

exit 0
