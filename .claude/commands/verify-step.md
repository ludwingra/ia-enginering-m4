---
name: verify-step
description: "Verificación post-step — evalúa acceptance criteria, ejecuta tests y actualiza progreso"
---

# Comando /verify-step — Verificación Post-Step ASD SDK v3.18.0

> **Uso:** Ejecutar `/verify-step` después de completar la implementación de un step.
> Implementa: Fase POST_VERIFY del Loop Fundamental.
> Skill asociada: `.claude/skills/verify-step/SKILL.md`
> Script motor: `hooks/post-verify.sh`

---

## Qué hace

1. Lee `claude-progress.json` para obtener el step actual
2. Identifica los acceptance criteria del step (del plan, HU, o contexto)
3. Corre tests, type-check y lint del scope del step
4. Evalúa inteligentemente si los criteria se cumplen
5. Si **PASS** → marca `acceptance_criteria_met[N] = true`, avanza `step_current`
6. Si **FAIL** → marca `status = "FAILED"`, ejecuta rollback automático de artifacts
7. Si todos los criteria met → señala que se debe ejecutar MERGE_READY_CHECKLIST

## Contrato del Agente Verificador

El agente que ejecuta /verify-step opera en modo READ-ONLY:
- **Permitido:** Read, Grep, Glob, Bash (solo comandos de lectura y tests: `npm test`, `tsc --noEmit`, `eslint`, `git status/log/diff`)
- **Prohibido:** Write, Edit, ni comandos que modifiquen archivos o estado de git
- Si detecta un problema: **REPORTA** con severidad (BLOCKER/MAJOR/MINOR), no corrige
- La corrección es responsabilidad del agente de ejecución en el siguiente ciclo

## Prerequisitos

- `claude-progress.json` debe tener `status: "IN_PROGRESS"`
- `rollback_ref` debe estar configurado (se registra en PRE-ACTION)
- `artifacts_produced[]` debe estar actualizado (se registra en POST-ACTION)
- El step debe tener implementación commiteada

## Flujo en el Loop Fundamental

```
Take Action → POST-ACTION → PRE-VERIFY → /verify-step (POST-VERIFY) → Repeat
                                              │
                                              ├── PASS → step_current++ → siguiente step
                                              ├── PASS (último) → DONE → /finishing-a-development-branch
                                              └── FAIL → rollback → re-intentar o debug
```

## Ejemplo de uso

```
# Después de implementar step 3 de 5:
/verify-step

# Output esperado (PASS):
# ✓ Step 3/5 verificado exitosamente.
#   acceptance_criteria_met[2] = true
#   step_current: 3 → 4
#   Siguiente: Step 4 — "Implementar endpoint PUT /orders/:id"

# Output esperado (FAIL):
# ✗ Step 3/5 — Verificación FALLIDA
#   Razón: 2 tests fallaron en CreateOrderUseCase.spec.ts
#   Rollback ejecutado: artifacts revertidos a abc1234
#   Opciones: A) Re-intentar  B) /systematic-debugging  C) Intervención humana
```

## Script motor standalone

El script `hooks/post-verify.sh` puede usarse directamente desde terminal:

```bash
# Marcar criteria[2] como passed
./hooks/post-verify.sh pass 2

# Marcar criteria[2] como failed (con rollback automático)
./hooks/post-verify.sh fail 2
```

---

*ASD SDK v3.17.0*
