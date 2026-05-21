#!/usr/bin/env bash
# ASD SDK v3.17.0 — Observability Hook
# Captura eventos PostToolUse y PostToolUseFailure → events.jsonl
# Configurado en .claude/settings.json, ejecutado automáticamente por Claude Code.
#
# Input: JSON en stdin con session_id, tool_name, tool_input, hook_event_name, agent_type
# Output: Appenda una línea JSONL a .claude/observability/events.jsonl

set -euo pipefail

OBS_DIR=".claude/observability"

mkdir -p "$OBS_DIR"

# Leer JSON completo de stdin
INPUT=$(cat)

# Extraer campos relevantes con jq (disponible en la mayoría de sistemas)
if ! command -v jq &>/dev/null; then
  # Fallback sin jq: escribir the input raw with timestamp to legacy file
  EVENTS_FILE="$OBS_DIR/events.jsonl"
  RAW_ESCAPED=$(echo "$INPUT" | head -c 500 | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g')
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"raw\":\"$RAW_ESCAPED\"}" >> "$EVENTS_FILE"
  exit 0
fi

EVENT_NAME=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Per-session event storage
EVENTS_DIR="$OBS_DIR/events"
mkdir -p "$EVENTS_DIR"
EVENTS_FILE="$EVENTS_DIR/${SESSION_ID}.jsonl"
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "none"')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "main"')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "main"')

# Extraer info específica según el tool
case "$TOOL_NAME" in
  Edit|Write)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
    DETAIL="{\"file\":\"$FILE_PATH\"}"
    ;;
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' | head -c 200)
    DETAIL="{\"cmd\":$(echo "$CMD" | jq -Rs .)}"
    ;;
  Read)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
    DETAIL="{\"file\":\"$FILE_PATH\"}"
    ;;
  Glob|Grep)
    PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""')
    DETAIL="{\"pattern\":$(echo "$PATTERN" | jq -Rs .)}"
    ;;
  *)
    DETAIL="{}"
    ;;
esac

# Determinar tipo de evento
if [ "$EVENT_NAME" = "PostToolUseFailure" ]; then
  EVENT_TYPE="tool_fail"
else
  EVENT_TYPE="tool_use"
fi

# Escribir evento JSONL
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "{\"ts\":\"$TS\",\"event\":\"$EVENT_TYPE\",\"session\":\"$SESSION_ID\",\"agent\":\"$AGENT_TYPE\",\"agent_id\":\"$AGENT_ID\",\"tool\":\"$TOOL_NAME\",\"detail\":$DETAIL}" >> "$EVENTS_FILE"

exit 0
