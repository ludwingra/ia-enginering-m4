#!/usr/bin/env bash
# pre-direct-edit.sh — PreToolUse matcher: Edit|Write
#
# COERCITIVO: bloquea cuando intent=work_item AND no hubo Agent dispatch reciente.
# ASD SDK v3.17.0 — Coercive enforcement, restaura tightness v3.17.0 (ADR-013).
#
# Design decision (graceful degradation):
#   Prefer false-negatives (over-allow) over false-positives (over-block).
#   If ANY check fails (missing jq, corrupt events.jsonl, unreadable intent),
#   the hook ALLOWS the action rather than blocking. This avoids locking out
#   the orchestrator due to environment issues. False-blocks are more harmful
#   than false-allows in an SDK development context.
set -euo pipefail

INTENT_FILE=".claude/observability/last-intent.json"
EVENTS_FILE=".claude/observability/events.jsonl"

# Read stdin (PreToolUse payload) — not strictly used but consume to avoid SIGPIPE
INPUT=$(cat 2>/dev/null || echo "{}")

# ─── Escape hatch ──────────────────────────────────────────────────────────
if [ "${ASD_DISPATCH_ENFORCE:-1}" = "0" ]; then
  exit 0
fi

# ─── No intent persisted → fresh session, allow ───────────────────────────
[ ! -f "$INTENT_FILE" ] && exit 0

# Need jq — degrade gracefully if missing
if ! command -v jq &>/dev/null; then
  exit 0
fi

INTENT=$(jq -r '.intent // "unknown"' "$INTENT_FILE" 2>/dev/null)
INTENT_TS=$(jq -r '.ts // ""' "$INTENT_FILE" 2>/dev/null)

# ─── Only enforce when intent=work_item ───────────────────────────────────
if [ "$INTENT" != "work_item" ]; then
  exit 0
fi

# ─── Check for recent agent_dispatch in events.jsonl ──────────────────────
# On any parse/read error → allow (graceful degradation, never block on error)
RECENT_DISPATCH=0
if [ -f "$EVENTS_FILE" ] && [ -n "$INTENT_TS" ]; then
  RECENT_DISPATCH=$(jq -s --arg ts "$INTENT_TS" \
    '[.[] | select(.event=="agent_dispatch" and .ts > $ts)] | length' \
    "$EVENTS_FILE" 2>/dev/null || echo "ERROR")
  # If jq failed or returned non-numeric (e.g. corrupt file) → allow
  if [ "$RECENT_DISPATCH" = "ERROR" ] || ! echo "$RECENT_DISPATCH" | grep -qE '^[0-9]+$'; then
    exit 0
  fi
fi

if [ "$RECENT_DISPATCH" -gt 0 ]; then
  # Dispatch happened after intent → this Edit likely from a subagent → allow
  exit 0
fi

# ─── BLOCK: orchestrator is editing directly without dispatch ─────────────
# Log the block event
mkdir -p .claude/observability
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null || echo '{}')
echo "{\"ts\":\"$TS\",\"event\":\"dispatch_blocked\",\"intent\":\"$INTENT\",\"intent_ts\":\"$INTENT_TS\",\"tool_input\":$TOOL_INPUT}" >> "$EVENTS_FILE"

cat <<'HOOK_OUTPUT'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "DISPATCH_REQUIRED: La intención del usuario fue implementación (work_item). DEBES dispatchar un agente vía Agent(subagent_type=...) antes de modificar archivos. Buscá un agente ASD en .claude/agents/ o usá fallback nativo (typescript-pro, refactoring-specialist, debugger, etc.). Para casos excepcionales: setear ASD_DISPATCH_ENFORCE=0 (requiere justificación en PROGRESS.md)."
  }
}
HOOK_OUTPUT
exit 0
