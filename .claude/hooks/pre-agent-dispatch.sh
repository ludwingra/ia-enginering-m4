#!/usr/bin/env bash
# ASD SDK v3.17.0 — Pre-Agent Dispatch Hook (PreToolUse matcher: Agent)
# Validates agent dispatch against dispatch-contract.json and provides guidance.
#
# Behavior (WI-INF-024):
#   - Reads .claude/config/dispatch-contract.json to determine mode (advisory|enforce)
#   - Env override: ASD_MATCHER_MODE=advisory|enforce takes precedence over contract
#   - No contract file        → advisory mode (backwards-compat)
#   - mode=advisory           → guidance only, exit 0 (never blocks)
#   - mode=enforce + asd_catalog     → allow silently
#   - mode=enforce + native_fallback → allow + advise fallback
#   - mode=enforce + not_recognized  → DENY (permissionDecision: deny)
#
# Graceful degradation: any jq/IO error → fall back to advisory behaviour with the
# hardcoded native list. Prefer false-negatives (over-allow) over false-positives
# (over-block) — same pattern as pre-direct-edit.sh.

set -euo pipefail

OBS_DIR=".claude/observability"
EVENTS_FILE="$OBS_DIR/events.jsonl"
CATALOG_FILE=".claude/config/agent-catalog.json"
CONTRACT_FILE=".claude/config/dispatch-contract.json"
PROGRESS_FILE=".claude/progress/claude-progress.json"

mkdir -p "$OBS_DIR"

INPUT=$(cat)

# Hardcoded native list — fallback when contract is missing or jq fails.
DEFAULT_NATIVE_AGENTS="general-purpose|Explore|Plan|code-reviewer|test-runner|debugger|refactoring-specialist|typescript-pro|performance-profiler|playwright-tester|principal-engineer|code-architect|legacy-modernizer|compliance-auditor|technical-debt-manager|api-documenter|commit-guardian|codebase-pattern-finder|tdd-red|tdd-green|test-generator|workflow-orchestrator|multi-agent-coordinator|context-manager|architecture-modernizer"

if ! command -v jq &>/dev/null; then
  RAW_ESCAPED=$(echo "$INPUT" | head -c 500 | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g')
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"agent_dispatch\",\"raw\":\"$RAW_ESCAPED\"}" >> "$EVENTS_FILE"
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "general-purpose"')
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "inherit"')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""' | head -c 100)
ISOLATION=$(echo "$INPUT" | jq -r '.tool_input.isolation // "none"')

# ─── Load dispatch contract ────────────────────────────────────────────────
CONTRACT_MODE="advisory"
NATIVE_AGENTS="$DEFAULT_NATIVE_AGENTS"

if [ -f "$CONTRACT_FILE" ]; then
  PARSED_MODE=$(jq -r '.mode // "advisory"' "$CONTRACT_FILE" 2>/dev/null || echo "advisory")
  if [ "$PARSED_MODE" = "enforce" ] || [ "$PARSED_MODE" = "advisory" ]; then
    CONTRACT_MODE="$PARSED_MODE"
  fi
  PARSED_NATIVES=$(jq -r '(.native_agents // []) | join("|")' "$CONTRACT_FILE" 2>/dev/null || echo "")
  if [ -n "$PARSED_NATIVES" ]; then
    NATIVE_AGENTS="$PARSED_NATIVES"
  fi
fi

# Env override takes precedence over contract mode.
EFFECTIVE_MODE="${ASD_MATCHER_MODE:-$CONTRACT_MODE}"
if [ "$EFFECTIVE_MODE" != "enforce" ] && [ "$EFFECTIVE_MODE" != "advisory" ]; then
  EFFECTIVE_MODE="advisory"
fi

# ─── Catalog-based validation ──────────────────────────────────────────────
AGENT_ROLE="unknown"
AGENT_TIER="unknown"
AGENT_PHASE="unknown"
AGENT_SOURCE="unknown"
CATALOG_STATUS="no_catalog"
DISPATCH_GUIDANCE=""

if [ -f "$CATALOG_FILE" ]; then
  # Support both nested shape (groups[].agents[]) and flat shape (.agents[]) defensively
  AGENT_ENTRY=$(jq -r --arg id "$SUBAGENT_TYPE" '[(.groups // {} | to_entries[].value.agents // []), (.agents // [])] | flatten | .[] | select(.id == $id)' "$CATALOG_FILE" 2>/dev/null || echo "")
  if [ -n "$AGENT_ENTRY" ]; then
    AGENT_ROLE=$(echo "$AGENT_ENTRY" | jq -r '.role // "unknown"')
    AGENT_TIER=$(echo "$AGENT_ENTRY" | jq -r '.tier // "unknown"')
    AGENT_PHASE=$(echo "$AGENT_ENTRY" | jq -r '.phase // "unknown"')
    AGENT_SOURCE=$(echo "$AGENT_ENTRY" | jq -r '.source // "unknown"')
    CATALOG_STATUS="asd_catalog"
    # ASD agent found — no guidance needed
  elif echo "$SUBAGENT_TYPE" | grep -qE "^($NATIVE_AGENTS)$"; then
    CATALOG_STATUS="native_fallback"
    AGENT_SOURCE="claude-native"
    DISPATCH_GUIDANCE="NATIVE_FALLBACK: Usando agente nativo '$SUBAGENT_TYPE' como fallback (no hay agente ASD equivalente). Esto es válido. Registrá en PROGRESS.md que se usó fallback nativo."
  else
    CATALOG_STATUS="not_recognized"
    DISPATCH_GUIDANCE="AGENT_NOT_RECOGNIZED: '$SUBAGENT_TYPE' no está en el catálogo ASD ni es un agente nativo conocido. Verificá que el nombre es correcto. Si la tarea no tiene agente adecuado, recordá el Principio #9: preguntá al usuario antes de auto-gestionar."
  fi
else
  # No catalog file — all agents are valid but warn
  if echo "$SUBAGENT_TYPE" | grep -qE "^($NATIVE_AGENTS)$"; then
    CATALOG_STATUS="native_fallback"
    AGENT_SOURCE="claude-native"
  else
    CATALOG_STATUS="no_catalog"
    DISPATCH_GUIDANCE="NO_CATALOG: agent-catalog.json no encontrado. No se puede validar el agente. Considerá generar el catálogo."
  fi
fi

# ─── Plan context (work item + step) ───────────────────────────────────────
PLAN_CONTEXT="none"
if [ -f "$PROGRESS_FILE" ]; then
  PLAN_CONTEXT=$(jq -r '
    if (.work_item.id // "") != "" then
      "\(.work_item.id)/step-\(.work_item.step_current // "?")"
    else
      "none"
    end
  ' "$PROGRESS_FILE" 2>/dev/null || echo "none")
  [ -z "$PLAN_CONTEXT" ] && PLAN_CONTEXT="none"
fi

# dispatch_decision is a semantic alias of catalog_status (both kept for back-compat)
DISPATCH_DECISION="$CATALOG_STATUS"

# ─── Log dispatch event ────────────────────────────────────────────────────
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "{\"ts\":\"$TS\",\"event\":\"agent_dispatch\",\"session\":\"$SESSION_ID\",\"subagent_type\":\"$SUBAGENT_TYPE\",\"model\":\"$MODEL\",\"isolation\":\"$ISOLATION\",\"role\":\"$AGENT_ROLE\",\"agent_role\":\"$AGENT_ROLE\",\"tier\":\"$AGENT_TIER\",\"agent_tier\":\"$AGENT_TIER\",\"agent_phase\":\"$AGENT_PHASE\",\"agent_source\":\"$AGENT_SOURCE\",\"catalog_status\":\"$CATALOG_STATUS\",\"dispatch_decision\":\"$DISPATCH_DECISION\",\"plan_context\":\"$PLAN_CONTEXT\",\"description\":$(echo "$DESCRIPTION" | jq -Rs .)}" >> "$EVENTS_FILE"

# ─── Enforce mode: deny not_recognized ─────────────────────────────────────
if [ "$EFFECTIVE_MODE" = "enforce" ] && [ "$CATALOG_STATUS" = "not_recognized" ]; then
  BLOCK_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$BLOCK_TS\",\"event\":\"dispatch_blocked\",\"session\":\"$SESSION_ID\",\"subagent_type\":\"$SUBAGENT_TYPE\",\"catalog_status\":\"$CATALOG_STATUS\",\"effective_mode\":\"$EFFECTIVE_MODE\",\"contract_mode\":\"$CONTRACT_MODE\"}" >> "$EVENTS_FILE"

  DENY_REASON="AGENT_NOT_RECOGNIZED: '$SUBAGENT_TYPE' no está en catálogo ASD ni en native_agents. Modo enforce activo. Verificá el nombre del agente o setá ASD_MATCHER_MODE=advisory para permitir (justificar en PROGRESS.md)."
  DENY_REASON_JSON=$(echo "$DENY_REASON" | jq -Rs .)
  cat <<HOOK_OUTPUT
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $DENY_REASON_JSON
  }
}
HOOK_OUTPUT
  exit 0
fi

# ─── Output guidance if needed (advisory or non-denying enforce cases) ─────
if [ -n "$DISPATCH_GUIDANCE" ]; then
  cat <<HOOK_OUTPUT
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "$DISPATCH_GUIDANCE"
  }
}
HOOK_OUTPUT
fi

exit 0
