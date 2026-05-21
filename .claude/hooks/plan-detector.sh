#!/bin/bash
# plan-detector.sh — UserPromptSubmit hook
# Detecta intención del usuario y guía al orquestador con additionalContext.
# Cubre 3 casos: planificación, work items nuevos, y reset por interacción.
#
# ASD SDK v3.17.0 — Advisor hook (exit 0 siempre, guía via additionalContext)

# Read the hook input from stdin
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Exit silently if no prompt or jq failed
[ -z "$PROMPT" ] && exit 0

# Normalize: lowercase for matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ─── Case 1: Plan keywords detected ────────────────────────────────────────
if echo "$PROMPT_LOWER" | grep -qE '\bplan[eo]?\b|\bplanific|\bdiseñar\s+plan|\bhacer\s+plan|\bmuestra.*plan|\bcrear\s+plan|\bgenerar\s+plan|\barquitectura\b'; then

  # Skip if user already invoked /plan explicitly
  if echo "$PROMPT_LOWER" | grep -qE '^\s*/plan\b'; then
    exit 0
  fi

  mkdir -p .claude/observability
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  PROMPT_EXCERPT=$(echo "$PROMPT" | head -c 80 | jq -Rs . 2>/dev/null || echo '""')
  cat > .claude/observability/last-intent.json <<INTENT_JSON
{
  "intent": "plan",
  "ts": "$TS",
  "session_id": "$SESSION_ID",
  "prompt_excerpt": $PROMPT_EXCERPT
}
INTENT_JSON

  cat <<'HOOK_OUTPUT'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "PLAN_MODE_DETECTED: El usuario ha solicitado planificación. DEBES cargar el skill plan-mode ejecutando /plan-mode antes de cualquier otra acción. Esto fuerza modelo Opus 4.6 y restricciones de solo lectura. Seguí el protocolo de planificación: gather context → analizar → generar plan estructurado → esperar aprobación. NO escribas código hasta que el plan sea aprobado. Recordá: máximo 4 steps por Work Item (PA-1). Si requiere más, dividí en partes WI-P1, WI-P2. Incluí Pre-flight Check (Fase 2.5) antes de presentar el plan."
  }
}
HOOK_OUTPUT
  exit 0
fi

# ─── Case 2: Work item / implementation keywords ───────────────────────────
if echo "$PROMPT_LOWER" | grep -qE '\bimplementa[r]?\b|\bcrea[r]?\b|\bagrega[r]?\b|\bcorregir\b|\bfix\b|\brefactor|\bdesarroll|\bconstruir\b|\bbugfix\b'; then

  mkdir -p .claude/observability
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  PROMPT_EXCERPT=$(echo "$PROMPT" | head -c 80 | jq -Rs . 2>/dev/null || echo '""')
  cat > .claude/observability/last-intent.json <<INTENT_JSON
{
  "intent": "work_item",
  "ts": "$TS",
  "session_id": "$SESSION_ID",
  "prompt_excerpt": $PROMPT_EXCERPT
}
INTENT_JSON

  cat <<'HOOK_OUTPUT'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "WORK_ITEM_DETECTED: Esta interacción parece ser un work item o tarea de implementación. RECORDATORIO POR INTERACCIÓN: 1) Evaluá si hay agente ASD o nativo para esta tarea. 2) Si no hay ninguno, PREGUNTÁ al usuario antes de proceder — proponé un plan con Agent teams. 3) NO heredes aprobaciones de interacciones anteriores — cada mensaje es una evaluación nueva. 4) Seguí el PROTOCOLO OBLIGATORIO de CLAUDE.md: pre-action → implementar → post-action → verificar."
  }
}
HOOK_OUTPUT
  exit 0
fi

# ─── Case 3: Default — Reset reminder ──────────────────────────────────────
# For any interaction, remind the orchestrator about per-interaction reset
mkdir -p .claude/observability
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PROMPT_EXCERPT=$(echo "$PROMPT" | head -c 80 | jq -Rs . 2>/dev/null || echo '""')
cat > .claude/observability/last-intent.json <<INTENT_JSON
{
  "intent": "question",
  "ts": "$TS",
  "session_id": "$SESSION_ID",
  "prompt_excerpt": $PROMPT_EXCERPT
}
INTENT_JSON

cat <<'HOOK_OUTPUT'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "INTERACTION_RESET: Nueva interacción del usuario. Cualquier aprobación de ejecución auto-gestionada de interacciones anteriores NO aplica. Evaluá desde cero: ¿La tarea requiere agente ASD, nativo, o checkpoint con el usuario?"
  }
}
HOOK_OUTPUT
exit 0
