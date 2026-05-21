---
name: greenfield-init
description: "Protocolo de inicio para proyectos nuevos — entrevista, brief y propuesta de arquitectura"
---

# /greenfield-init — Protocolo de Inicio para Proyectos Nuevos (Greenfield)

> **ASD SDK v3.18.0** — Ejecutar cuando el proyecto es nuevo y no existen repos.
> Reemplaza al context-collector estándar para proyectos greenfield.
> Resultado: `project-brief.json` + `architecture-proposal.json` listos para scaffolding.

---

## PREREQUISITOS

```bash
# 1. Estás en un workspace root (vacío o con .claude/ del SDK)
ls .claude/CLAUDE.md 2>/dev/null || echo "Ejecutá primero: npx ts-node ~/.asd-sdk/bin/asd-init.ts . --multi-repo --new-project --system-name=<nombre>"

# 2. Verificar que el SDK está disponible
ls ~/.asd-sdk/bin/asd-init.ts && echo "SDK OK"
```

---

## FASE GF-1 — INGESTA DE CONTEXTO

### STEP GF-1.1 — Detectar archivos de contexto

Buscar carpeta `data/` en el workspace root (o la ruta indicada por el usuario):

```bash
ls -la data/ 2>/dev/null || echo "No hay carpeta data/ — toda la información vendrá de la entrevista"
```

Si existe `data/`:
1. Listar todos los archivos: `.md`, `.txt`, `.json`, `.yaml`, `.yml`, `.pdf`, `.docx`
2. Leer cada archivo
3. Clasificar cada archivo en una de estas categorías:
   - `architecture` — diagramas, decisiones técnicas, stack
   - `business` — modelo de negocio, usuarios, dominio
   - `integration` — APIs externas, specs OpenAPI, webhooks
   - `requirements` — funcionalidades, user stories, acceptance criteria
   - `other` — no clasificable

4. Extraer información relevante de cada archivo:
   - Entidades mencionadas
   - Servicios/módulos mencionados
   - Tecnologías mencionadas
   - Restricciones o requisitos
   - Integraciones externas

5. Informar al usuario qué se encontró:

```
📂 ARCHIVOS DE CONTEXTO DETECTADOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [architecture] data/architecture.md
    → Stack: NestJS, PostgreSQL, Redis
    → Patrón: Hexagonal
    → Servicios mencionados: users, payments, notifications

  [integration] data/api-spec.yaml
    → APIs externas: Stripe, SendGrid
    → Endpoints: 12 definidos

  [business] data/requirements.md
    → Dominio: fintech
    → User stories: 8 identificadas
    → Usuarios: B2C + admin

Total: 3 archivos procesados
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FASE GF-2 — ENTREVISTA GREENFIELD

> Preguntar SOLO los campos que NO pudieron inferirse de los archivos de contexto.
> Los campos inferidos se presentan como `[INFERIDO: valor]` para confirmación.

### Bloque A — Identidad y Negocio

```
A1. ¿Cuál es el propósito principal del sistema? (1-2 oraciones)
A2. ¿Quiénes son los usuarios principales? (ej: clientes B2C, operadores internos, administradores)
A3. ¿Cuál es la etapa del proyecto? MVP | Crecimiento | Madurez
A4. ¿Hay deadlines o milestones próximos?
```

### Bloque B — Stack y Arquitectura

```
B1. ¿Cuál es el patrón arquitectónico objetivo?
    Hexagonal | DDD | MVC | Microservicios | Monolito Modular | Evento-Driven
B2. ¿Cómo se comunican los servicios? REST | gRPC | Events | GraphQL | Mixto
B3. ¿Hay bus de eventos? Kafka | RabbitMQ | SQS | Ninguno
B4. ¿Cuáles son las integraciones externas clave? (APIs de terceros, webhooks, etc.)
```

### Bloque C — Infraestructura

```
C1. ¿Cloud provider? AWS | GCP | Azure | On-premise | Mixto
C2. ¿Estrategia de despliegue? Blue/Green | Canary | Rolling | Manual
C3. ¿Entornos necesarios? dev | staging | prod | otros
```

### Bloque D — Seguridad y Compliance

```
D1. ¿Regulaciones aplicables? GDPR | PCI-DSS | SARLAFT | HIPAA | Ninguna | Otra
D2. ¿Mecanismo de autenticación? JWT | OAuth2 | API Keys | Session | Otro
D3. ¿Dónde se almacenarán secretos? .env | Vault | AWS Secrets Manager | Otro
```

### Bloque E — Calidad y Testing

```
E1. ¿Cobertura mínima requerida? (default: 80%)
E2. ¿SonarQube/SonarCloud se va a usar?
E3. ¿Framework de testing preferido? Jest | Vitest | Pytest | JUnit | Otro
E4. ¿E2E requerido? Playwright | Cypress | Ninguno
```

### Bloque F — Git y Workflow

```
F1. ¿Estrategia de branching? GitFlow | Trunk-based | GitHub Flow
F2. ¿PR policy? (reviews requeridos, protección de branches)
F3. ¿CI/CD? GitHub Actions | GitLab CI | Jenkins | Otro
```

### Bloque H — Greenfield: Definición del Sistema (NUEVO)

> Este bloque es EXCLUSIVO de proyectos greenfield y define la estructura del sistema.

```
H1. ¿Cuántos servicios/repos necesitás?
    (o describí el sistema y te propongo la cantidad)

H2. Describí la funcionalidad principal del sistema.
    (user stories de alto nivel, qué hace el sistema, para quién)

H3. ¿Hay un frontend? ¿Qué tipo?
    SPA | SSR (Next.js) | Mobile (React Native) | Admin Dashboard | Múltiple

H4. ¿Hay APIs públicas? ¿Para consumo de terceros o solo internas?

H5. ¿Necesitás workers/jobs en background?
    (colas de mensajes, cron jobs, procesamiento batch)

H6. ¿Bases de datos?
    PostgreSQL | MongoDB | MySQL | DynamoDB | Redis | Mixto

H7. ¿Tenés archivos de contexto, arquitectura o integraciones?
    Indicá la ruta (ej: "./data")
    [Si ya se procesaron en GF-1, confirmar lo encontrado]

H8. ¿Hay preferencia de framework?
    Backend:  NestJS | Express | FastAPI | Spring Boot | Go std | Sin preferencia
    Frontend: Next.js | Angular | React+Vite | Vue | Sin preferencia

H9. ¿Monorepo (un git con packages) o multi-repo (un git por servicio)?
    [Default: multi-repo — es el modo activo]

H10. ¿Necesitás un repo de infraestructura separado?
     (IaC con OpenTofu/Terraform, CI/CD pipelines, Helm charts)
```

### Reglas de la entrevista

1. **Agrupar preguntas** — Presentar máximo 4 preguntas por turno.
2. **Priorizar Bloque H** — Es lo más importante para greenfield. Empezar por H1-H2 para entender el sistema.
3. **Inferir agresivamente** — Si los archivos de `data/` contestaron algo, mostrarlo como `[INFERIDO]` y pedir confirmación.
4. **No repetir** — Si algo ya se contestó, no volver a preguntar.
5. **Sugerir opciones** — Para cada pregunta, ofrecer opciones concretas basadas en el contexto.

### Orden recomendado de preguntas

```
Turno 1: H1, H2 (entender qué es el sistema)
Turno 2: H3, H6, H8 (stack y tipo de proyecto)
Turno 3: A1, A2, A3 (identidad y negocio — pueden inferirse de H1-H2)
Turno 4: B1, B2, B3 (arquitectura)
Turno 5: H4, H5, H10 (APIs, workers, infra)
Turno 6: C1, D1, D2 (cloud, seguridad)
Turno 7: E1, E3, F1, F3 (calidad, git)
Turno 8: Confirmar todo lo inferido
```

---

## FASE GF-3 — GENERAR PROJECT-BRIEF

Con toda la información recopilada, generar `.claude/project-brief.json` siguiendo el schema `templates/schemas/project-brief.schema.json`.

```bash
# Verificar que se generó correctamente
cat .claude/project-brief.json | head -20
```

Informar al usuario:

```
PROJECT BRIEF GENERADO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Sistema:       {{system_name}}
  Dominio:       {{domain}}
  Stage:         {{stage}}
  Repos pedidos: {{repos_count}}
  Stack:         {{backend}} + {{frontend}}
  Archivos:      {{context_files_count}} procesados

Guardado en: .claude/project-brief.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Activando greenfield-architect para propuesta de arquitectura...
```

---

## FASE GF-4 — ACTIVAR GREENFIELD-ARCHITECT

### Configuración del agente

- **Modelo:** `claude-opus-4-6` (OBLIGATORIO — decisiones arquitectónicas requieren máxima capacidad)
- **Agente:** `greenfield-architect` (definido en `templates/agents/greenfield-architect.md`)
- **Input:** `.claude/project-brief.json` + archivos de `data/`
- **Output esperado:** `.claude/architecture-proposal.json`

### Activación

Despachar el agente `greenfield-architect` usando el Agent tool de Claude Code:

```
Agent: greenfield-architect
Model: opus
Prompt:
  Leer .claude/project-brief.json y los archivos de contexto listados.
  Seguir las instrucciones de templates/agents/greenfield-architect.md.
  Generar architecture-proposal.json con la propuesta completa.
```

### Sub-agentes (activación condicional)

Si el greenfield-architect determina que necesita diseño detallado:

**Backend complejo (3+ servicios o dominio complejo):**
```
Agent: nativo Claude Code
Model: opus
Prompt: [Definido en greenfield-architect.md — PASO 4]
```

**Frontend complejo (múltiples roles o SPA + dashboard):**
```
Agent: nativo Claude Code
Model: opus
Prompt: [Definido en greenfield-architect.md — PASO 4]
```

### Esperar aprobación

El greenfield-architect presentará la propuesta al usuario y esperará aprobación.
El loop de aprobación (opciones A-F) se ejecuta dentro del agente.

---

## FASE GF-5 — INSTRUCCIONES POST-APROBACIÓN

Una vez que el usuario aprueba la propuesta:

```
ARQUITECTURA APROBADA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Archivos generados:
  ✓ .claude/project-brief.json
  ✓ .claude/architecture-proposal.json

SIGUIENTE PASO — Scaffolding de repos:

  Ejecutá en la terminal (fuera de Claude):

  npx ts-node ~/.asd-sdk/bin/asd-init.ts . \
    --multi-repo --system-name={{SYSTEM_NAME}} --from-proposal

  Esto va a:
  1. Leer architecture-proposal.json
  2. Crear {{N}} repos con estructura de código
  3. Git init + commit inicial en cada repo
  4. Configurar el workspace hub (.claude/ compartido)
  5. Generar .mcp.json con acceso a todos los repos

  Después, volvé a Claude y ejecutá:
  /workspace-bootstrap
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## RESUMEN DEL FLUJO

```
/greenfield-init
│
├── GF-1: Ingestar archivos de data/ (si existen)
│   └── Clasificar, extraer, informar
│
├── GF-2: Entrevista greenfield (Bloques A-H)
│   └── Preguntar solo lo pendiente, inferir lo posible
│
├── GF-3: Generar project-brief.json
│   └── Validar contra schema
│
├── GF-4: Activar greenfield-architect (Opus 4.6)
│   ├── Análisis de dominio → bounded contexts
│   ├── Propuesta de repos → stack + estructura
│   ├── [Opcional] Sub-agentes Opus 4.6 (backend/frontend)
│   ├── Generar architecture-proposal.json
│   └── Presentar propuesta → loop de aprobación (A-F)
│
└── GF-5: Instrucciones post-aprobación
    └── "Ejecutá: npx ts-node ... --from-proposal"
```

---

*ASD SDK v3.18.0 — /greenfield-init — Protocolo para Proyectos Nuevos*
