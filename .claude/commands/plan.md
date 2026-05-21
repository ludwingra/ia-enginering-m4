---
name: plan
description: "Entra en modo planificación con Opus 4.6 — analiza, estructura y diseña antes de ejecutar"
model: opus
---

# Comando /plan — Plan Model (Opus 4.6) — ASD SDK v3.17.0

> **Uso:** `/plan [descripción de la tarea]` o simplemente `/plan` para entrar en modo planificación.
> **Modelo:** Opus 4.6 (forzado por el skill plan-mode)
> **Restricción:** Solo lectura — no se escribe código hasta que el plan sea aprobado.

---

## ACTIVACIÓN

Al ejecutar `/plan`, el sistema:

1. **Carga el skill `plan-mode`** con modelo Opus 4.6
2. **Entra en Plan Mode** (herramientas restringidas a solo lectura)
3. **Ejecuta el protocolo de planificación** descrito abajo

---

## PROTOCOLO DE PLANIFICACIÓN

### STEP P1 — Gather Context

Leer archivos de contexto del proyecto:

```bash
# Leer estado actual
cat .claude/progress/claude-progress.json
cat .claude/memory/PROJECT_CONTEXT.md
cat .claude/memory/ARCHITECTURE.md
cat .claude/memory/TECH_DECISIONS.md
git branch --show-current
git log --oneline -5
```

**Criterio:** Entender el estado actual del proyecto antes de planificar.

### STEP P2 — Analizar la tarea

Si el usuario proporcionó `$ARGUMENTS`:
- Clasificar el tipo: `feature` | `bugfix` | `refactor` | `docs` | `infra`
- Identificar archivos afectados (usar Glob/Grep para explorar)
- Detectar riesgos y dependencias

Si NO proporcionó argumentos:
- Preguntar: "¿Qué tarea querés planificar?"

### STEP P3 — Generar Plan Estructurado

Presentar al usuario un plan con este formato:

**Nota:** La sección "Estrategia de Agentes" se genera automáticamente por Fase 3.5 (ver skill plan-mode). La heurística elige entre `multi-dispatch` (WIs simples) o `multi-dispatch-pro` (WIs complejos, >=3 dominios, >=4 steps, infra). No escribirla manualmente.

```markdown
## Plan: [Título]

**Tipo:** [feature|bugfix|refactor|docs|infra]
**Complejidad:** [baja|media|alta] ([N] steps)
**Branch sugerido:** [feat|fix|refactor|docs]/[nombre-descriptivo]

### Steps de implementación

| # | Step | Agente | Pool | Modelo | Archivos afectados |
|---|------|--------|------|--------|-------------------|
| 1 | [desc] | [nombre] | ASD/nativo | opus/sonnet | [archivos] |
| 2 | [desc] | [nombre] | ASD/nativo | opus/sonnet | [archivos] |

### Estrategia de Agentes
[Bloque auto-generado por plan-mode Fase 3.5.
 Heurística: multi-dispatch (COMPACT/MINIMAL/EXTENDED) para WIs simples | multi-dispatch-pro (flujo por tipo) para WIs complejos.
 Ver multi-dispatch/SKILL.md y multi-dispatch-pro/SKILL.md para detalle.]

### Dependencias entre steps
- Step 2 depende de Step 1 (secuencial)
- Steps 3 y 4 son independientes (paralelo)

### Riesgos
- [riesgo 1]: [mitigación]

### Criterios de aceptación
- [ ] [criterio 1]
- [ ] [criterio 2]
```

### STEP P4 — Aprobación

Preguntar al usuario:

```
¿Aprobás este plan?
  [S] Sí — iniciar ejecución
  [M] Modificar — ajustar el plan
  [N] No — cancelar
```

**Si S (aprueba):**
1. Registrar `rollback_ref` = `git rev-parse HEAD`
2. Actualizar `claude-progress.json` con steps del plan
3. Salir de plan mode → comenzar ejecución con agentes Sonnet 4.6

**Si M (modificar):**
- Preguntar qué cambiar y regenerar el plan

**Si N (cancelar):**
- Volver a estado IDLE

---

## EJEMPLOS DE USO

```bash
# Planificar una feature específica
/plan Implementar endpoint REST para usuarios con autenticación JWT

# Planificar sin descripción (preguntará)
/plan

# Planificar un bugfix
/plan Corregir error de memoria en el worker de procesamiento
```

---

*ASD SDK v3.17.0 — Plan Model — Opus 4.6*
