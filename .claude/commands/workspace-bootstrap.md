---
name: workspace-bootstrap
description: "Bootstrap paralelo multi-repo — inicializa múltiples repos con asd-init simultáneamente"
---

# /workspace-bootstrap — Protocolo de Bootstrap Paralelo Multi-Repo

> ASD SDK v3.18.0 — Ejecutar desde el workspace root (donde está `.claude/memory/WORKSPACE.md`)

---

## PREREQUISITOS

Antes de ejecutar este comando, verificar:

```bash
# 1. Estás en el workspace root
ls .claude/memory/WORKSPACE.md && echo "OK" || echo "ERROR: no es un workspace ASD"

# 2. El .mcp.json tiene acceso a todos los repos
cat .mcp.json | grep filesystem -A 10
```

Si falta alguno, ejecutar primero:
```bash
npx ts-node <sdk-path>/bin/asd-init.ts . --multi-repo --system-name=<nombre>
```

---

## FASE 3 — Bootstrap Paralelo (TÚ EJECUTAS ESTO)

### 3.1 Leer WORKSPACE.md y detectar repos sin bootstrap

Leer `.claude/memory/WORKSPACE.md`. Identificar los repos con `Bootstrapped = NO` en la tabla de estado.

Para cada repo a bootstrapear, recolectar:
- Nombre y ruta absoluta
- Stack (lang, framework, testRunner) — inferido del discovery

### 3.2 Construir prompts por repo

Para cada repo a bootstrapear, el prompt del agente es:

```
## Contexto
Repo:         {{REPO_NAME}}
Ruta:         {{REPO_PATH}}
SDK command:  npx ts-node {{SDK_PATH}} {{REPO_PATH}}
Workspace:    {{WORKSPACE_ROOT}}/.claude/  ← memoria compartida (ya existe)

Stack conocido:
  Lenguaje:   {{LANG}}
  Framework:  {{FRAMEWORK}}
  Testing:    {{TEST_RUNNER}}

## Tareas

### 1. Verificar working tree
git -C {{REPO_PATH}} status --porcelain
Si hay output NO esperado: DETENER y reportar. No continuar.

### 2. Ejecutar bootstrap local
npx ts-node {{SDK_PATH}} {{REPO_PATH}}
Capturar salida completa.

### 3. Verificar stack detectado
Leer `.claude/CLAUDE.md` generado. Si Testing no coincide con {{TEST_RUNNER}}:
  - Corregir el campo en CLAUDE.md
  - Agregar nota en `.claude/memory/PROJECT_CONTEXT.md`

### 4. Agregar referencia al Workspace en CLAUDE.md del repo

Agregar al final de `{{REPO_PATH}}/.claude/CLAUDE.md`:

---
## WORKSPACE COMPARTIDO

Este repo es parte del sistema {{SYSTEM_NAME}}.
Memoria compartida del sistema: {{WORKSPACE_ROOT}}/.claude/memory/

Para contexto cross-repo, leer:
  - {{WORKSPACE_ROOT}}/.claude/memory/ARCHITECTURE.md
  - {{WORKSPACE_ROOT}}/.claude/memory/API_CONTRACTS.md
  - {{WORKSPACE_ROOT}}/.claude/memory/AGENT_COMMS.md

Para Work Items que solo afectan este repo: trabajar aquí normalmente.
Para Work Items cross-repo: abrir Claude desde {{WORKSPACE_ROOT}}

### 5. Pre-rellenar PROJECT_CONTEXT.md del repo

En `{{REPO_PATH}}/.claude/memory/PROJECT_CONTEXT.md`, inferir y completar:
  - Propósito específico de este servicio
  - APIs que expone (inferir de rutas/handlers en el código fuente)
  - Servicios que consume (inferir de llamadas HTTP, SDKs importados, env vars)
  - Agregar: "Ver API_CONTRACTS.md en workspace para contratos formales"

### 6. Commit local en el repo
git -C {{REPO_PATH}} add .claude/
git -C {{REPO_PATH}} commit -m "chore: bootstrap ASD SDK local config"

## Output requerido (responder EXACTAMENTE en este formato)

REPO: {{REPO_NAME}}
STATUS: PASS | FAIL | PARTIAL
STACK_OK: S | N
APIS_DETECTADAS: [lista o "ninguna inferida"]
DEPS_DETECTADAS: [lista o "ninguna inferida"]
ISSUES: [lista o "ninguno"]
```

### 3.3 Despachar agentes en paralelo

Usar `dispatching-parallel-agents` skill para lanzar todos los agentes simultáneamente.
Cada agente recibe el prompt del paso 3.2 con sus variables completadas.

**Esperar a que TODOS completen antes de continuar con Fase 4.**

---

## FASE 4 — Sintetizar Memoria Compartida (TÚ EJECUTAS ESTO)

Con los reportes de todos los agentes:

### 4.1 Actualizar `WORKSPACE.md`

Actualizar la tabla "Estado de Bootstrap":
- Repos con STATUS=PASS → `Bootstrapped: YES`
- Repos con STATUS=FAIL → `Bootstrapped: NO (FAILED — ver ISSUES_LOG)`
- Repos con STATUS=PARTIAL → `Bootstrapped: PARTIAL`

### 4.2 Actualizar `API_CONTRACTS.md`

Para cada relación detectada (APIS_DETECTADAS + DEPS_DETECTADAS cruzadas):

```markdown
## Contratos inferidos

### {{REPO_A}} → {{REPO_B}}
- Endpoint/Evento: [de APIS_DETECTADAS de repo-a]
- Payload: [PENDIENTE — inferido]
- Autenticación: [PENDIENTE — inferido]
- Estado: INFERIDO (pendiente validación con /init de cada repo)
```

### 4.3 Actualizar `ARCHITECTURE.md`

Agregar diagrama de dependencias basado en DEPS_DETECTADAS de cada repo:

```markdown
## Diagrama de dependencias inferido

[repo-a] ──→ [repo-b]
[repo-c] ──→ [repo-b]

## Repos por capa
Frontend:    [lista]
Backend:     [lista]
Shared/Libs: [lista]
Infra:       [lista]
```

### 4.4 Verificar `.mcp.json`

```bash
cat .mcp.json | grep -A 20 "filesystem"
```

Verificar que cada repo aparece como argumento. Si falta alguno: agregar.

---

## REPORTE FINAL

Emitir este reporte al usuario:

```
WORKSPACE MULTI-REPO CONFIGURADO
==================================

Workspace root:   [ruta]
Sistema:          [nombre]
Repos integrados: N

REPOS:
  ✓ [repo-a] — bootstrap OK — APIs detectadas: X
  ✓ [repo-b] — bootstrap OK — stack corregido
  ⚠ [repo-c] — bootstrap PARTIAL — [razón]
  ✗ [repo-d] — FAILED — [razón, acción manual requerida]

MEMORIA COMPARTIDA:
  ✓ WORKSPACE.md         — registry de N repos actualizado
  ✓ ARCHITECTURE.md      — diagrama inferido
  ✓ API_CONTRACTS.md     — X contratos inferidos, Y pendientes
  ✓ AGENT_COMMS.md       — vacío, listo para handoffs

PRÓXIMOS PASOS:
1. Para Work Items en un solo repo:
   cd <workspace>/<repo> && claude && /init

2. Para Work Items cross-repo:
   cd <workspace> && claude && /init

3. Completar contexto pendiente:
   Ejecutar /init en cada repo → context-collector (Bloques A-G)

CONTRATOS PENDIENTES DE VALIDACIÓN:
  [lista de relaciones que necesitan confirmación]
```

---

*ASD SDK v3.18.0 — /workspace-bootstrap — Phase 3 & 4 Protocol*
