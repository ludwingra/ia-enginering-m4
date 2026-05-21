---
name: work-item
description: "Gestiona work items del proyecto — entry point obligatorio para desarrollo con dispatch forzado de agentes"
---

# Comando /work-item — Entry Point de Desarrollo ASD SDK

> **Uso:** `/work-item [descripcion]` o `/work-item` para auto-detectar modo.
> Invariante: El orquestador NUNCA ejecuta implementacion directamente — siempre via Agent().

---

## FLAGS

| Invocacion                     | Comportamiento                                         |
|--------------------------------|--------------------------------------------------------|
| `/work-item`                   | Auto-detecta modo (nuevo o continuar)                  |
| `/work-item [descripcion]`     | Modo nuevo con descripcion pre-cargada                 |
| `/work-item --status`          | Muestra estado del WI activo sin ejecutar nada          |
| `/work-item --cancel`          | Cancela WI activo, rollback a rollback_ref              |
| `/work-item --list`            | Lista historico de WIs desde wi-counter.json            |
| `/work-item --skip-plan`       | Fuerza steps minimos sin invocar /plan (max 4 steps)   |

---

## SECCION 1 — DETECCION DE MODO

### D1 — Flags especiales

Si `$ARGUMENTS` contiene `--status`, `--cancel`, o `--list`, ejecuta la accion y DETENTE:

**--status:** Leer `claude-progress.json` via `readWorkItem()`. Mostrar:

```
WORK ITEM — Estado actual

  WI activo:    [id]
  Branch:       [branch]
  Progreso:     Step [N]/[M] — [step_label]
  Status:       [EXECUTING|VERIFYING|BLOCKED|PLANNED]
  Completados:  [lista de steps DONE]
  Pendientes:   [lista de steps restantes]
  Rollback ref: [sha]
```

Si no hay WI activo: `No hay Work Item activo. Usa /work-item para crear uno.`

**--cancel:** Leer `rollback_ref` de `claude-progress.json`, ejecutar `git checkout [rollback_ref] -- .`, limpiar estado con `cleanStaleState()`, marcar CANCELLED en `wi-counter.json`.
Mostrar: `WI [id] cancelado. Rollback a [sha] ejecutado.`

**--list:** Leer `wi-counter.json` y mostrar:

```
WORK ITEM — Historico

  ID       | Tipo     | Titulo          | Status    | Fecha
  ---------|----------|-----------------|-----------|------------
  WI-001   | feature  | config-cache    | DONE      | 2026-04-01
```

### D2 — Detectar modo principal

Leer estado con `readProgressFile()`. Evaluar con `isStaleWorkItem()` para detectar WIs abandonados.

| Condicion                                                    | Modo         |
|--------------------------------------------------------------|--------------|
| WI activo con status EXECUTING, VERIFYING o BLOCKED          | CONTINUAR    |
| `$ARGUMENTS` tiene descripcion (texto sin --)                | NUEVO        |
| No hay argumentos ni WI activo                               | NUEVO (pedir)|

Si stale: ejecutar `cleanStaleState()` y tratar como NUEVO.

### D3 — Validar slot disponible

Antes de crear un WI nuevo, verificar que no haya otro activo. Si falla:

```
ERROR: Ya existe un WI activo — [id] (status: [status]).
  Opciones:
    /work-item --cancel   — cancelar el WI activo
    /work-item             — continuar el WI activo
```

---

## SECCION 2 — MODO NUEVO

### N1 — Clasificar tipo

Usar `classifyWorkItemType(description)`. Si ambiguo: preguntar al usuario.

### N2 — Generar nomenclatura

Usar `generateWorkItemId(type, shortName, counterPath)` para ID.
Usar `generateBranchName(wiId, type)` para branch name.

### N3 — Estimar steps y asignar agentes

Descomponer la tarea en steps concretos. Usar `selectAgentsForSteps()` para asignar agentes. Para cada step:

1. Buscar agente ASD en AGENT_REGISTRY.md → `{ source: "asd" }`
2. Si no hay ASD, buscar nativo de Claude Code → `{ source: "native" }`
3. Si no hay ninguno: CHECKPOINT — informar al usuario, esperar aprobacion

**VALIDACION:** Cada step DEBE tener agente asignado y al menos 1 acceptance criterion.

### N4 — Evaluar tamano (regla PA-1)

Usar `needsSplit(estimateStepCount(description, type))`. Si >4 steps: SPLIT obligatorio.

Reglas del split:
- Maximo 4 steps por parte
- Nomenclatura: `WI-[NNN]-P[X]-[tipo]-[nombre-corto]`
- Partes secuenciales: P1 debe estar mergeado antes de P2

### N5 — Cargar skills

Usar `getSkillsForType(type)` para obtener skills required y conditional.

### N6 — Evaluar necesidad de /plan

| Condicion                              | Accion                                      |
|----------------------------------------|----------------------------------------------|
| `--skip-plan` en flags                 | Saltar /plan, usar steps minimos             |
| <=2 steps Y tipo simple (bugfix/docs)  | Auto-plan, no invocar /plan                  |
| >2 steps O tipo feature/infra          | Preguntar al usuario si quiere /plan         |
| Usuario pide planificacion             | Invocar `/plan` con contexto pre-cargado     |

### N7 — Presentar clasificacion al usuario

Mostrar con formato exacto:

```
WORK ITEM — Clasificacion

  Descripcion:  [descripcion original]
  Tipo:         [tipo]
  Nomenclatura: [WI-NNN-tipo-nombre]
  Branch:       [prefijo/WI-NNN-nombre]

  Tamano estimado: [N] steps
    Step 1: [label] ([agente])
    Step 2: [label] ([agente])
    Step 3: [label] ([agente])

  Skills a cargar: [lista]

  Estrategia de Agentes (Arquitecto + Líder + Especialista):
    Dispatch obligatorio via Agent tool — consultá agent-catalog.json
    y AGENT_REGISTRY.md. Prioridad: ASD → nativo → CHECKPOINT.
    Loop por step: pre-action → Arquitecto valida → Líder despacha
    Especialista → post-action → verify-step.
    (Generado automáticamente por multi-dispatch o multi-dispatch-pro según heurística de Fase 3.5 — ver /multi-dispatch)

  Necesita planificacion detallada? [S/N]
    S -> Invocar /plan con contexto pre-cargado
    N -> Proceder con steps minimos mostrados arriba

  Aprobar y comenzar? [S / M(odificar) / N(o)]
```

Si requiere split (>4 steps):

```
WORK ITEM — Split Requerido (regla PA-1)

  Descripcion:   [descripcion]
  Tipo:          [tipo]
  Tamano:        ~[N] steps -> SPLIT en [X] partes

  WI-[NNN]-P1-[tipo]-[nombre-parte1] ([M] steps)
    Step 1: [label] ([agente])
    Step 2: [label] ([agente])

  WI-[NNN]-P2-[tipo]-[nombre-parte2] ([M] steps)
    Step 1: [label] ([agente])

  Cada parte genera su propio branch y PR.
  Se ejecutan SECUENCIALMENTE (P2 depende de P1 mergeado).

  Estrategia de Agentes (Arquitecto + Líder + Especialista):
    Dispatch obligatorio via Agent tool — consultá agent-catalog.json
    y AGENT_REGISTRY.md. Prioridad: ASD → nativo → CHECKPOINT.
    Loop por step: pre-action → Arquitecto valida → Líder despacha
    Especialista → post-action → verify-step.
    (Generado automáticamente por multi-dispatch o multi-dispatch-pro según heurística de Fase 3.5 — ver /multi-dispatch)

  Aprobar split? [S / M(odificar) / N(o)]
```

### N8 — Procesar aprobacion

**Si S:** Escribir `claude-progress.json` con `writeWorkItem()`, actualizar `wi-counter.json`, crear branch con `git checkout -b [branch-name]`. Ir a SECCION 4.

**Si M:** Preguntar que cambiar, ajustar, volver a N7.

**Si N:** No incrementar contador, volver a IDLE.

---

## SECCION 3 — MODO CONTINUAR

Leer estado con `readWorkItem()`. Verificar branch con `git branch --show-current`.

Mostrar:

```
WORK ITEM — Continuacion detectada

  WI activo:    [id]
  Branch:       [branch]
  Progreso:     Step [N]/[M] — [step_label]
  Status:       [status]
  Completados:  [lista steps DONE]
  Pendientes:   [lista steps restantes]

  Ultimo commit: [sha] — "[mensaje]"
  Rollback ref:  [sha]

  Continuar desde Step [N]? [S / Ver plan completo / Cancelar WI]
```

**Si S:** Ir a SECCION 4 retomando desde `step_current`.
**Si Ver plan:** Mostrar todos los steps, preguntar de nuevo.
**Si Cancelar:** Ejecutar logica de `--cancel`.

---

## SECCION 4 — LOOP DE EJECUCION POR STEP

Ejecutar para cada step desde `step_current` hasta `step_total`.

### E1 — PRE-ACTION

```bash
git rev-parse HEAD          # Guardar como rollback_ref
git status --porcelain      # Advertir si hay cambios no staged
git branch --show-current   # Verificar branch correcto
```

Guardar `rollback_ref` en `claude-progress.json`.

### E2 — Confirmacion pre-dispatch

```
Step [N]/[M] — [step_label]
  Agente:     [agent_name] ([source], [model_tier] → [recommended_model])
  Skills:     [skills del step]
  Archivos:   [archivos esperados]
  Rollback:   [sha]

  Ejecutando...
```

### E3 — DISPATCH del agente

Registrar en `AGENT_COMMS.md` y ejecutar:

```
Agent(
  model: "[recommended_model from agent-catalog.json]",
  subagent_type: "[agent-name]",
  prompt: """
    WORK ITEM: [wi_id]
    STEP: [N]/[M] — [step_label]
    BRANCH: [branch]
    ROLLBACK_REF: [sha]

    CONTEXTO:
    - Steps anteriores produjeron: [artifacts de steps previos]

    INSTRUCCIONES:
    [instrucciones especificas del step]

    ACCEPTANCE CRITERIA:
    1. [criterio 1]
    2. [criterio 2]

    RESTRICCION: Commitear con mensaje "progress: [WI-NNN] — step [N]/[M]"
  """
)
```

### E4 — POST-ACTION

1. `git add` + `git commit -m "progress: [WI-NNN] — step [N]/[M]"` (si el agente no lo hizo)
2. Actualizar `claude-progress.json` via `writeWorkItem()` — marcar step DONE, registrar artifacts
3. Agregar entrada narrativa en `PROGRESS.md`
4. Actualizar `AGENT_COMMS.md` con status COMPLETED

### E5 — VERIFICACION

Invocar `/verify-step` automaticamente.

**Si PASS y no es ultimo step:** Usar `advanceStep()`, volver a E1.
**Si PASS y es ultimo step:** Ir a SECCION 5.
**Si FAIL:** Rollback con `git checkout [rollback_ref] -- [artifacts]`, marcar FAILED. Mostrar:

```
Step [N]/[M] — VERIFICACION FALLIDA
  Razon: [detalle del fallo]
  Rollback ejecutado: artifacts revertidos a [sha]

  Opciones:
    A) Re-intentar (max 2 retries)
    B) /systematic-debugging
    C) Intervencion humana (BLOCKED)
```

Max 2 retries por step. Despues: marcar BLOCKED, esperar humano.

---

## SECCION 5 — COMPLETACION

### F1 — Ejecutar MERGE_READY_CHECKLIST (12 gates)

Evaluar cada gate:

- GATE_1: `npm test` — unit tests pasan (BLOQUEANTE)
- GATE_2: `npm test -- --coverage` — coverage >= 80% (BLOQUEANTE)
- GATE_4: `npx tsc --noEmit` — 0 errores TS (BLOQUEANTE)
- GATE_5: `npx eslint .` — 0 errores lint (BLOQUEANTE)
- GATE_6: Todos los acceptance_criteria_met = true (BLOQUEANTE)
- GATE_7: PROGRESS.md tiene entradas del WI (WARNING)
- GATE_8: `npx detect-secrets scan` — clean (BLOQUEANTE)
- GATE_9: `git commit --allow-empty -m "chore: session-end [WI-NNN]"` (BLOQUEANTE)
- GATE_10: Branch actualizado con develop (RECOMENDADO)
- GATE_11: DOC_SYNC — MANUAL.md, README.md, CHANGELOG.md si aplica (BLOQUEANTE)
- GATE_12: Agent security scan — agentes en AGENT_REGISTRY.md (BLOQUEANTE)

### F2 — Mostrar resumen

```
WORK ITEM — Completado

  WI:          [id]
  Branch:      [branch]
  Steps:       [M]/[M] completados

  MERGE_READY_CHECKLIST:
    GATE_1  Unit tests pasan            [PASS|FAIL]
    GATE_2  Coverage >= 80%             [PASS (XX%)|FAIL]
    GATE_4  tsc --noEmit = 0 errores   [PASS|FAIL]
    GATE_5  ESLint = 0 errores         [PASS|FAIL]
    GATE_6  Acceptance criteria met     [PASS [N/N]|FAIL]
    GATE_7  PROGRESS.md actualizado     [PASS|WARN]
    GATE_8  detect-secrets scan         [PASS|FAIL]
    GATE_9  Commit session-end          [PASS]
    GATE_10 Branch actualizado          [PASS|WARN]
    GATE_11 DOC_SYNC completado         [PASS|SKIP|FAIL]
    GATE_12 Agent security scan         [PASS|SKIP|FAIL]

  Resultado: [READY FOR PR | BLOCKED — N gates fallaron]
```

### F3 — Finalizar

Si gates BLOQUEANTES pasan: marcar DONE via `writeWorkItem()`, actualizar `wi-counter.json`. Mostrar:

```
WI [id] DONE. Listo para PR.
  Proximos pasos:
    1. git push -u origin [branch]
    2. gh pr create --base develop
    3. Solicitar code review
```

Si hay gates BLOQUEANTES fallidos: listar fallos, proponer acciones correctivas, NO marcar como DONE.

---

## REGLAS CRITICAS

1. **NUNCA ejecutar implementacion directamente** — siempre via Agent()
2. **Cada step DEBE tener agente** — buscar en AGENT_REGISTRY.md primero, luego nativos, luego CHECKPOINT
3. **Respetar PA-1** — maximo 4 steps por WI, split si necesita mas
4. **Conventional commits** — `progress: WI-NNN — step X/Y` para commits intermedios
5. **DOC_SYNC** — si el WI es visible al usuario, incluir docs update como step o en ultimo step
6. **Solo un WI activo a la vez** — no se puede iniciar otro si hay uno en EXECUTING/BLOCKED
7. **Rollback siempre disponible** — registrar rollback_ref ANTES de cada step
8. **Max 2 retries por step** — despues de 2 fallos, marcar BLOCKED y esperar humano
9. **Estrategia de Agentes obligatoria** — todo plan presentado al usuario DEBE incluir bloque de Estrategia de Agentes (generado por multi-dispatch o multi-dispatch-pro según heurística de Fase 3.5). Si no existe, ejecutar la skill de dispatch antes de presentar.

---

*ASD SDK v3.17.0*
