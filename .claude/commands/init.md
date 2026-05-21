---
name: init
description: "Protocolo de inicio de sesión ASD — carga contexto, valida config y establece estado inicial"
---

# Comando /init — Protocolo de Inicio de Sesión ASD SDK v3.18.0

> **Uso:** Ejecutar `/init` al inicio de cada sesión de Claude Code.
> Implementa: Fase 1 (Initializer Agent) → Fase 3 (context-collector) → Fase 4 (sdk-config)

---

## FASE 1 — INITIALIZER AGENT

> Capability: `filesystem_read`, `git_read` ÚNICAMENTE. No escribir hasta Step I5.

### STEP I1 — Verificar estado del repositorio

```bash
git status --porcelain
git branch --show-current
```

**Criterio de éxito:**
- Working tree limpio (sin cambios no commiteados), O
- La rama activa es la esperada según `.claude/memory/PROGRESS.md`

**Si falla:** Reportar al humano antes de continuar. NO proceder en auto.

```
⚠ INITIALIZER: Working tree no limpio.
  Rama actual: [rama]
  Archivos modificados:
    [lista]
  Opciones:
    A) Hacer stash y continuar
    B) Commitear los cambios pendientes
    C) Abortar y resolver manualmente
  ¿Cuál preferís?
```

### STEP I2 — Detectar modo de inicio

Leer `.claude/memory/PROGRESS.md` y `.claude/memory/AGENT_REGISTRY.md`.

| Condición | Modo | Acción |
|-----------|------|--------|
| No existen los archivos | BOOTSTRAP | Activar context-collector (Fase 3) |
| Existen y status=DONE | CONTINUATION | Cargar estado anterior |
| Existen y status=FAILED | RECOVERY | Activar rollback protocol |
| Existen y status=IN_PROGRESS | CONTINUATION | Retomar desde step_current |

**Emitir:**
```
INITIALIZER: Modo detectado → [BOOTSTRAP | CONTINUATION | RECOVERY]
```

### STEP I3 — Verificar Skills Tier-1

Verificar que existan en `.claude/skills-manifest.json` con `installed: true`:

```
✓ systematic-debugging
✓ test-driven-development
✓ verification-before-completion
✓ finishing-a-development-branch
✓ using-git-worktrees
```

**Si alguna falta:**
```
✗ ERROR BLOQUEANTE: Skills Tier-1 no instaladas.
  Ejecutar: npx skills add obra/superpowers@[skill-faltante]
  No se puede continuar hasta instalarlas.
```

### STEP I4 — Health check MCPs

Verificar que los MCPs críticos respondan:

| MCP | Criticidad | Si falla |
|-----|-----------|---------|
| filesystem | CRÍTICO | ERROR BLOQUEANTE |
| git | CRÍTICO | ERROR BLOQUEANTE |
| context7 | IMPORTANTE | Registrar en ISSUES_LOG.md — modo degradado |
| sequential-thinking | IMPORTANTE | Registrar en ISSUES_LOG.md — modo degradado |

Si filesystem o git fallan:
```
✗ INITIALIZER BLOQUEADO: MCP [nombre] no responde.
  Verificar .mcp.json y que el servidor MCP esté instalado.
  Comando: npx @modelcontextprotocol/server-filesystem --help
```

### STEP I5 — Generar SESSION_CONTEXT.json

Escribir en `.claude/SESSION_CONTEXT.json`:

```json
{
  "schema_version": "1.0",
  "session_id": "sess-YYYYMMDD-HHmmss",
  "initialized_at": "[ISO8601]",
  "anchor_commit": "[SHA del HEAD actual]",
  "active_work_item": "[branch activo o null]",
  "active_agent": "initializer",
  "progress_step": 0,
  "progress_total": 0,
  "token_budget_used_pct": 0,
  "skills_verified": ["systematic-debugging", "test-driven-development",
                      "verification-before-completion", "finishing-a-development-branch",
                      "using-git-worktrees"],
  "mcps_active": ["filesystem", "git", "context7", "sequential-thinking"],
  "last_checkpoint_sha": null,
  "project_name": "[nombre del proyecto]",
  "_note": "Generado y sobreescrito por Initializer Agent en cada sesión."
}
```

### STEP I6 — Commit anchor de sesión

```bash
git commit --allow-empty -m "chore: session-start [session_id]"
```

Este commit es el **punto de rollback de toda la sesión**. Registrar el SHA en `SESSION_CONTEXT.json.anchor_commit`.

### STEP I7 — Emitir señal READY

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INITIALIZER READY
  Session ID:  sess-YYYYMMDD-HHmmss
  Modo:        [BOOTSTRAP | CONTINUATION | RECOVERY]
  Skills:      5/5 Tier-1 verificadas
  MCPs:        [lista de activos]
  Anchor:      [SHA del commit]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Si modo = CONTINUATION o RECOVERY:** Mostrar el Work Item activo y el step actual, luego preguntar:
```
Work Item activo: [ticket_id] — [title]
Step actual: [N]/[M] — [step_label]
Status: [status]

¿Continuar desde aquí? (S/N)
```

**Si modo = BOOTSTRAP:** Continuar automáticamente a Fase 3 (context-collector).

---

## FASE 3 — CONTEXT-COLLECTOR

> Capability: `filesystem_read`, `git_read` ÚNICAMENTE.
> Solo se activa en modo BOOTSTRAP o cuando el humano lo solicita explícitamente.

### ETAPA 1 — Ingesta Automática

Solicitar o leer automáticamente:

```
Por favor, adjuntá (o indicá la ruta de) los siguientes archivos del proyecto:

  REQUERIDOS:
  □ package.json / pom.xml / requirements.txt / go.mod / Cargo.toml
  □ README.md (si existe)

  OPCIONALES (enriquecen el análisis):
  □ tsconfig.json / .eslintrc
  □ docker-compose.yml / Dockerfile
  □ .env.example (sin valores reales)
  □ sonar-project.properties
  □ ADRs, wikis, diagramas de arquitectura
  □ Exports de Confluence o Notion

  También podés pegar el contenido directamente en el chat.
```

Analizar cada archivo recibido y generar borradores con:
- `[INFERIDO: valor]` — completado automáticamente, confirmar o corregir
- `[PENDIENTE]` — no se pudo inferir, preguntar en Etapa 2

### ETAPA 2 — Preguntas Dirigidas

Preguntar **SOLO los campos `[PENDIENTE]`**, agrupados por bloque temático:

**Bloque A — Identidad y Negocio**
```
A1. ¿Cuál es el propósito principal del sistema? (1-2 oraciones)
A2. ¿Quiénes son los usuarios principales? (ej: clientes B2C, operadores internos)
A3. ¿Cuál es la etapa del proyecto? MVP | Crecimiento | Madurez | Legacy
A4. ¿Hay deadlines o milestones próximos?
```

**Bloque B — Stack y Arquitectura**
```
B1. ¿Cuál es el patrón arquitectónico objetivo? Hexagonal | DDD | MVC | Microservicios | Monolito Modular
B2. ¿Cómo se comunican los servicios? REST | gRPC | Events | GraphQL | Mixto
B3. ¿Hay bus de eventos? Kafka | RabbitMQ | SQS | Ninguno
B4. ¿Cuáles son las integraciones externas clave?
```

**Bloque C — Infraestructura**
```
C1. ¿Cloud provider? AWS | GCP | Azure | On-premise | Mixto
C2. ¿Estrategia de despliegue? Blue/Green | Canary | Rolling | Manual
C3. ¿Entornos existentes? dev | staging | prod | otros
```

**Bloque D — Seguridad y Compliance**
```
D1. ¿Regulaciones aplicables? GDPR | PCI-DSS | SARLAFT | HIPAA | Ninguna | Otra
D2. ¿Mecanismo de autenticación? JWT | OAuth2 | API Keys | Session | Otro
D3. ¿Dónde se almacenan secretos? .env | Vault | AWS Secrets Manager | Otro
```

**Bloque E — Calidad y Testing**
```
E1. ¿Cobertura mínima requerida? (default: 80%)
E2. ¿SonarQube/SonarCloud activo?
E3. ¿Hay tests existentes? ¿qué framework?
E4. ¿E2E requerido? Playwright | Cypress | Ninguno
```

**Bloque F — Git y Workflow**
```
F1. ¿Estrategia de branching actual?
F2. ¿PR policy? (reviews requeridos, protección de branches)
F3. ¿CI/CD activo? ¿qué plataforma?
```

**Bloque G — Legacy específico** (solo si `projectType === 'legacy'`)
```
G1. ¿Motivación del análisis? Refactor | Migración | Modernización | Auditoría
G2. ¿Hay tests existentes? ¿qué porcentaje de coverage?
G3. ¿Zonas críticas (no tocar sin autorización)?
G4. ¿Deuda técnica conocida?
```

### ETAPA 3 — Síntesis

Con toda la información recopilada, actualizar los 8 archivos de memoria:

1. `.claude/memory/PROJECT_CONTEXT.md` — negocio, usuarios, compliance
2. `.claude/memory/ARCHITECTURE.md` — stack, patrón, diagrama AS-IS
3. `.claude/memory/TECH_DECISIONS.md` — ADRs actualizados
4. `.claude/memory/PROGRESS.md` — estado narrativo inicial
5. `.claude/memory/AGENT_REGISTRY.md` — agentes activados para el proyecto
6. `.claude/memory/API_CONTRACTS.md` — si se detectaron APIs
7. `.claude/memory/ISSUES_LOG.md` — issues detectados durante onboarding
8. `.claude/memory/AGENT_COMMS.md` — inicializado vacío

**Para proyectos legacy:** Activar en paralelo (usando git worktrees):
```
→ code-analyzer:          Análisis estático, anti-patterns
→ architecture-detective: Reverse-engineering arquitectura AS-IS
→ dependency-auditor:     CVEs, licencias, dependencias obsoletas
→ test-coverage-analyst:  Mapeo de cobertura existente
→ api-contract-extractor: Extracción de contratos implícitos
```

---

## FASE 4 — SDK-CONFIG

> Capability: `filesystem_read`, `filesystem_write`.
> Solo se activa si `.claude/settings.json` está incompleto o no existe.

### ETAPA 1 — Lectura de configuración existente

Leer (si existen):
- `.claude/settings.json`
- `.mcp.json`
- Cualquier documento de arquitectura adjunto (PDFs, ADRs, C4 diagrams)

Inferir automáticamente:
- Modelo por rol (orquestador vs agentes) según complejidad del proyecto
- Herramientas permitidas según stack detectado
- MCPs necesarios según tecnologías
- Variables de entorno requeridas

### ETAPA 2 — Preguntas Dirigidas

Preguntar SOLO lo no inferido:

```
1. MODELO (default: opus para orquestador, sonnet para agentes)
   ¿Ajustar modelos?
   □ claude-opus-4    (orquestador — máxima capacidad)
   □ claude-sonnet-4-5 (agentes — balance calidad/costo)
   □ claude-haiku-4-5  (tareas simples — máxima velocidad)

2. MCPs ADICIONALES (marcar los que aplican al proyecto):
   □ sonarqube        → Quality gates, análisis estático
   □ playwright       → E2E testing, browser automation
   □ github           → PRs, Issues, GitHub Actions
   □ kubernetes       → Clusters K8s, Helm, namespaces
   □ docker           → Containers locales
   □ openapi          → Specs OpenAPI/Swagger
   □ shadcn-ui        → Componentes shadcn v4
   □ magic-mcp        → UI de alta calidad
   □ cloudflare       → Workers, KV, R2, edge
   □ figma            → Tokens de diseño
   □ osv-vulnerability → CVE database
   □ comet-opik       → Observabilidad LLMs

3. VARIABLES DE ENTORNO Y SECRETOS
   ¿Variables requeridas por MCPs? (ej: SONAR_TOKEN, GITHUB_TOKEN)

4. WORKTREES PATH (default: .claude/agents/)
   ¿Ruta alternativa para worktrees de agentes paralelos?
```

### ETAPA 3 — Generación de configuración

Generar `.claude/settings.json` definitivo:
```json
{
  "model": "claude-opus-4",
  "agent_model": "claude-sonnet-4-5",
  "token_budget": {
    "compact_threshold_pct": 60,
    "checkpoint_threshold_pct": 85
  },
  "allowedTools": [...],
  "env": { "PROJECT_ROOT": "...", ... },
  "hooks": { ... }
}
```

Generar `.mcp.json` con MCPs activados (reemplazar `/PROJECT_PATH_PLACEHOLDER` con la ruta real del proyecto).

Mostrar resumen para confirmación humana:

```
SDK-CONFIG: Configuración generada
  Modelo orquestador: claude-opus-4
  Modelo agentes:     claude-sonnet-4-5
  MCPs activos:       filesystem, git, context7, sequential-thinking, [extras]
  Tools permitidas:   [lista]
  Worktrees path:     .claude/agents/

¿Confirmar y escribir archivos? (S/N)
```

---

## RESUMEN DEL PROTOCOLO /init

```
/init
  └── FASE 1: Initializer Agent
        I1. git status --porcelain ✓
        I2. Detectar modo (BOOTSTRAP | CONTINUATION | RECOVERY)
        I3. Verificar 5 skills Tier-1
        I4. Health check MCPs críticos
        I5. Generar SESSION_CONTEXT.json
        I6. git commit --allow-empty "chore: session-start [id]"
        I7. Emitir señal READY
        │
        ├── Si CONTINUATION/RECOVERY → mostrar Work Item activo → preguntar si continuar
        │
        └── Si BOOTSTRAP →
              FASE 3: context-collector
                E1. Ingesta automática de archivos
                E2. Preguntas dirigidas (solo [PENDIENTE])
                E3. Síntesis → 8 archivos de memoria
                │
                └── FASE 4: sdk-config (si settings incompletos)
                      E1. Leer config existente
                      E2. Preguntas MCP/modelos/env
                      E3. Generar settings.json + .mcp.json → confirmar
```

---

*ASD SDK v3.17.0*
