#!/usr/bin/env bash
# ASD SDK v3.17.0 — Progress Tracker Hook
# Trackea comandos Bash relevantes para progreso (PostToolUse matcher: Bash)
# Detecta patrones clave: git commit, npm test, tsc, y los registra como hitos.
#
# Input: JSON en stdin con session_id, tool_name, tool_input (command)
# Output: Appenda evento JSONL cuando detecta comando de progreso.

set -euo pipefail

OBS_DIR=".claude/observability"

mkdir -p "$OBS_DIR"

INPUT=$(cat)

if ! command -v jq &>/dev/null; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Per-session event storage
EVENTS_DIR="$OBS_DIR/events"
mkdir -p "$EVENTS_DIR"
EVENTS_FILE="$EVENTS_DIR/${SESSION_ID}.jsonl"
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Detectar comandos de progreso
MILESTONE=""

case "$CMD" in
  *"git commit"*)
    MILESTONE="commit"
    ;;
  *"npm test"*|*"npx vitest"*)
    MILESTONE="test_run"
    ;;
  *"tsc --noEmit"*|*"tsc"*)
    MILESTONE="typecheck"
    ;;
  *"eslint"*)
    MILESTONE="lint"
    ;;
  *"git push"*)
    MILESTONE="push"
    ;;
  *"git merge"*|*"git pull"*)
    MILESTONE="sync"
    ;;
  *)
    # No es un comando de progreso, salir silenciosamente
    exit 0
    ;;
esac

# Registrar milestone
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
CMD_SHORT=$(echo "$CMD" | head -c 150)
echo "{\"ts\":\"$TS\",\"event\":\"progress_milestone\",\"session\":\"$SESSION_ID\",\"milestone\":\"$MILESTONE\",\"cmd\":$(echo "$CMD_SHORT" | jq -Rs .)}" >> "$EVENTS_FILE"

exit 0
