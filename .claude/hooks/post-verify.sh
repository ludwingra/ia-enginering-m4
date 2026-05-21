#!/usr/bin/env bash
# ASD SDK v3.17.0 — Post-Verify Hook
# Motor bash para actualizar claude-progress.json después de verificación de step.
#
# Uso:
#   ./hooks/post-verify.sh pass <index>    # Marca criteria[index]=true, step_current++
#   ./hooks/post-verify.sh fail <index>    # Marca criteria[index]=false, status=FAILED, rollback
#
# Requiere: jq
# Input: resultado (pass|fail) e índice del acceptance criteria

set -euo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────
PROGRESS_FILE=".claude/progress/claude-progress.json"

# ─── Validaciones ─────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "⚠ jq no encontrado. post-verify requiere jq para actualizar claude-progress.json" >&2
  echo "  Instalar:" >&2
  echo "    macOS:  brew install jq" >&2
  echo "    Ubuntu: sudo apt install jq" >&2
  echo "    Windows: choco install jq" >&2
  echo "" >&2
  echo "  Mientras tanto, verificación registrada manualmente:" >&2
  echo "  Resultado: $1 | Criterio: $2" >&2
  exit 0
fi

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "ERROR: $PROGRESS_FILE no encontrado." >&2
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "Uso: $0 <pass|fail> <criteria_index>" >&2
  echo "  Ejemplo: $0 pass 2" >&2
  exit 1
fi

RESULT="$1"
INDEX="$2"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [[ "$RESULT" != "pass" && "$RESULT" != "fail" ]]; then
  echo "ERROR: Primer argumento debe ser 'pass' o 'fail'. Recibido: '$RESULT'" >&2
  exit 1
fi

if ! [[ "$INDEX" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Segundo argumento debe ser un número entero. Recibido: '$INDEX'" >&2
  exit 1
fi

# ─── Leer estado actual ──────────────────────────────────────────────────────
STEP_CURRENT=$(jq -r '.step_current' "$PROGRESS_FILE")
STEP_TOTAL=$(jq -r '.step_total' "$PROGRESS_FILE")
STEP_LABEL=$(jq -r '.step_label // "unknown"' "$PROGRESS_FILE")
STATUS=$(jq -r '.status' "$PROGRESS_FILE")
ROLLBACK_REF=$(jq -r '.rollback_ref // empty' "$PROGRESS_FILE")

# ─── PASS ─────────────────────────────────────────────────────────────────────
if [ "$RESULT" = "pass" ]; then
  NEW_STEP=$((STEP_CURRENT + 1))
  LAST_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

  # Verificar si todos los criteria serán true después de esta actualización
  ALL_MET=$(jq --argjson idx "$INDEX" '
    .acceptance_criteria_met
    | to_entries
    | map(if .key == $idx then .value = true else . end)
    | all(. == true)
  ' "$PROGRESS_FILE" 2>/dev/null || echo "false")

  if [ "$ALL_MET" = "true" ]; then
    NEW_STATUS="DONE"
  else
    NEW_STATUS="IN_PROGRESS"
  fi

  # Actualizar claude-progress.json
  jq --argjson idx "$INDEX" \
     --argjson new_step "$NEW_STEP" \
     --arg new_status "$NEW_STATUS" \
     --arg ts "$TIMESTAMP" \
     --arg last_commit "$LAST_COMMIT" \
     --arg step_label "$STEP_LABEL" '
    .acceptance_criteria_met[$idx] = true
    | .step_current = $new_step
    | .status = $new_status
    | .last_verified_commit = $last_commit
    | .updated_at = $ts
    | .history += [{
        "action": "verify_pass",
        "criteria_index": $idx,
        "step_label": $step_label,
        "step_moved_to": $new_step,
        "new_status": $new_status,
        "commit": $last_commit,
        "timestamp": $ts
      }]
  ' "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp" && mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"

  echo "✓ PASS: acceptance_criteria_met[$INDEX] = true"
  echo "  step_current: $STEP_CURRENT → $NEW_STEP"
  echo "  status: $STATUS → $NEW_STATUS"
  echo "  last_verified_commit: $LAST_COMMIT"

  if [ "$NEW_STATUS" = "DONE" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ALL ACCEPTANCE CRITERIA MET — Ejecutar MERGE_READY_CHECKLIST"
    echo "  Invocar: /finishing-a-development-branch"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi

  exit 0
fi

# ─── FAIL ─────────────────────────────────────────────────────────────────────
if [ "$RESULT" = "fail" ]; then
  # Marcar criteria como false y status como FAILED
  jq --argjson idx "$INDEX" \
     --arg ts "$TIMESTAMP" \
     --arg step_label "$STEP_LABEL" '
    .acceptance_criteria_met[$idx] = false
    | .status = "FAILED"
    | .updated_at = $ts
    | .history += [{
        "action": "verify_fail",
        "criteria_index": $idx,
        "step_label": $step_label,
        "timestamp": $ts
      }]
  ' "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp" && mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"

  echo "✗ FAIL: acceptance_criteria_met[$INDEX] = false"
  echo "  status: $STATUS → FAILED"

  # Rollback automático si hay rollback_ref y artifacts_produced
  if [ -n "$ROLLBACK_REF" ]; then
    ARTIFACTS=$(jq -r '.artifacts_produced[]' "$PROGRESS_FILE" 2>/dev/null)
    if [ -n "$ARTIFACTS" ]; then
      echo ""
      echo "  Ejecutando rollback de artifacts a $ROLLBACK_REF..."
      ROLLBACK_OK=true
      while IFS= read -r artifact; do
        # Validar que el path solo contiene caracteres seguros
        if ! [[ "$artifact" =~ ^[a-zA-Z0-9_./-]+$ ]]; then
          echo "    ⚠ Path inválido, skip: $artifact"
          continue
        fi
        if git show "$ROLLBACK_REF:$artifact" &>/dev/null; then
          git checkout "$ROLLBACK_REF" -- "$artifact" 2>/dev/null && \
            echo "    ↩ $artifact" || \
            echo "    ⚠ No se pudo revertir: $artifact"
        else
          echo "    ⚠ Archivo no existía en $ROLLBACK_REF: $artifact (se mantiene)"
        fi
      done <<< "$ARTIFACTS"

      # Registrar rollback en history
      jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
         --arg ref "$ROLLBACK_REF" '
        .history += [{
          "action": "rollback_executed",
          "rollback_ref": $ref,
          "artifacts_reverted": .artifacts_produced,
          "timestamp": $ts
        }]
      ' "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp" && mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"

      echo "  Rollback completado."
    else
      echo "  No hay artifacts_produced para revertir."
    fi
  else
    echo "  ⚠ No hay rollback_ref configurado. Rollback omitido."
  fi

  echo ""
  echo "  El agente puede re-intentar el step o solicitar intervención."
  exit 1
fi
