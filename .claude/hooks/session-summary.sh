#!/usr/bin/env bash
# ASD SDK v3.17.0 — Session Summary Hook
# Captura SessionEnd → genera session-summary.json con métricas agregadas
# Lee events.jsonl y produce un resumen filtrado por session_id.

set -euo pipefail

OBS_DIR=".claude/observability"
SUMMARY_DIR="$OBS_DIR/summaries"

mkdir -p "$SUMMARY_DIR"

INPUT=$(cat)

if ! command -v jq &>/dev/null; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

SESSION_FILE="$OBS_DIR/events.jsonl"

# Si no hay eventos, salir
if [ ! -f "$SESSION_FILE" ]; then
  exit 0
fi

EVENTS_FILE="$OBS_DIR/events.jsonl"

# Filtrar eventos de esta sesión
SESSION_EVENTS=$(jq -c --arg sid "$SESSION_ID" 'select(.session == $sid)' "$SESSION_FILE" 2>/dev/null) || true

if [ -z "$SESSION_EVENTS" ]; then
  # Escribir evento de cierre y salir
  echo "{\"ts\":\"$TS\",\"event\":\"session_end\",\"session\":\"$SESSION_ID\",\"metrics\":{\"total_events\":0}}" >> "$EVENTS_FILE"
  exit 0
fi

# Calcular métricas con jq
SUMMARY=$(echo "$SESSION_EVENTS" | jq -s --arg sid "$SESSION_ID" --arg ts "$TS" '
{
  session_id: $sid,
  generated_at: $ts,
  metrics: {
    total_events: length,
    tool_uses: [.[] | select(.event == "tool_use")] | length,
    tool_failures: [.[] | select(.event == "tool_fail")] | length,
    agents_started: [.[] | select(.event == "agent_start")] | length,
    agents_stopped: [.[] | select(.event == "agent_stop")] | length,
    unique_agents: ([.[] | .agent] | unique | length),
    unique_tools: ([.[] | select(.tool != null) | .tool] | unique | length),
    files_touched: ([.[] | select(.detail.file != null) | .detail.file] | unique | length)
  },
  agents: (
    [.[] | select(.agent != null)] | group_by(.agent) | map({
      agent: .[0].agent,
      events: length,
      tool_uses: [.[] | select(.event == "tool_use")] | length,
      failures: [.[] | select(.event == "tool_fail")] | length
    })
  ),
  tools: (
    [.[] | select(.tool != null)] | group_by(.tool) | map({
      tool: .[0].tool,
      uses: length
    }) | sort_by(-.uses)
  ),
  timeline: {
    first_event: (sort_by(.ts) | first | .ts),
    last_event: (sort_by(.ts) | last | .ts)
  }
}
' 2>/dev/null) || SUMMARY="{\"session_id\":\"$SESSION_ID\",\"error\":\"failed to aggregate\"}"

# Guardar resumen
SAFE_SID=$(echo "$SESSION_ID" | tr -cd '[:alnum:]-_')
echo "$SUMMARY" > "$SUMMARY_DIR/${SAFE_SID}.json"

# Escribir evento de cierre en el stream
echo "{\"ts\":\"$TS\",\"event\":\"session_end\",\"session\":\"$SESSION_ID\"}" >> "$EVENTS_FILE"

# Actualizar ISSUES_LOG.md con resumen de sesión
ISSUES_LOG=".claude/memory/ISSUES_LOG.md"
if [ -f "$ISSUES_LOG" ]; then
  TOOL_USES=$(echo "$SUMMARY" | jq -r '.metrics.tool_uses // 0')
  FAILURES=$(echo "$SUMMARY" | jq -r '.metrics.tool_failures // 0')
  AGENTS=$(echo "$SUMMARY" | jq -r '.metrics.unique_agents // 0')
  echo "$TS [session-summary] [INFO] Session $SESSION_ID ended — $TOOL_USES tool calls, $FAILURES failures, $AGENTS agents" >> "$ISSUES_LOG"
fi

# Write session summary to vault (graceful — no-op if vault not found)
if [ -n "$SUMMARY" ] && [ "$SUMMARY" != "null" ]; then
  echo "$SUMMARY" | npx tsx bin/lib/vault-session-writer.ts 2>/dev/null || true
fi

# Update sessions.json index — mark session as ended with summary
if [ -f "$OBS_DIR/sessions.json" ] && command -v jq &>/dev/null; then
  jq --arg sid "$SESSION_ID" \
    'map(if .sessionId == $sid then .hasEnded = true | .hasSummary = true else . end)' \
    "$OBS_DIR/sessions.json" > "$OBS_DIR/sessions.json.tmp" && mv "$OBS_DIR/sessions.json.tmp" "$OBS_DIR/sessions.json"
fi

exit 0
