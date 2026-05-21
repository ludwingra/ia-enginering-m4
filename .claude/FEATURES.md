# FEATURES.md — ASD SDK v3.18.0

> Generado automáticamente por `asd-init` — NO EDITAR MANUALMENTE.
> Regenerá ejecutando `asd-init --upgrade` o `asd-init --refresh-features`.

## Agentes disponibles (90)

### Architecture & Planning (11 agentes)

- **adr-generator** _(model: sonnet)_ — Genera Architectural Decision Records (ADRs) estructurados para documentar decisiones técnicas.
- **architecture-fitness-evaluator** _(model: sonnet)_ — Evalua fitness functions de arquitectura: metricas automatizadas que verifican que las caracteristicas arquitectonicas se mantienen en el tiempo.
- **architecture-modernizer** _(model: sonnet)_ — Diseña estrategias de descomposición de monolitos y migración a event-driven architecture.
- **code-architect** _(model: sonnet)_ — Diseña blueprints de implementación comprensivos analizando patrones existentes del codebase.
- **context-collector** _(model: sonnet)_ — Gathers and organizes project context from codebases, documentation, and configurations to provide comprehensive situational awareness for agents.
- **context-manager** _(model: sonnet)_ — Gestiona estado compartido, sincronización de datos y retrieval eficiente entre agentes.
- **hexagonal-architecture-evaluator** _(model: sonnet)_ — Evalúa principios de Arquitectura Hexagonal (Ports & Adapters): aislamiento del dominio, inversión de dependencias y separación infrastructure/application/domain.
- **java-architect** — Designs Java/JVM application architectures using Spring Boot, microservices patterns, and enterprise integration with focus on performance and maintainability.
- **layered-architecture-evaluator** _(model: sonnet)_ — Evalúa arquitectura en capas (N-Tier/MVC): separación de responsabilidades, dependencias unidireccionales, aislamiento de capas y convenciones de proyecto.
- **legacy-modernizer** _(model: sonnet)_ — Transformación incremental de sistemas legacy usando Strangler Fig pattern con zero downtime.
- **nextjs-architecture-expert** — Master of Next.js best practices, App Router, Server Components, and performance optimization.

```ts
Agent(subagent_type: "adr-generator", model: "opus", prompt: "...")
```

### Backend & APIs (9 agentes)

- **api-design-evaluator** _(model: sonnet)_ — Evalúa diseño de APIs REST y GraphQL: recursos, verbos HTTP, status codes, versionado, paginación, errores, documentación, auth y rate limiting.
- **api-documenter** _(model: haiku)_ — Genera documentación de API completa: OpenAPI 3.1 specs, portales interactivos, ejemplos de código multi-lenguaje y guías de integración.
- **backend-architect** — Designs backend system architectures including API design, data modeling, service decomposition, and scalability patterns for distributed systems.
- **backend-developer** — Develops backend services and APIs with focus on clean architecture, database integration, authentication, error handling, and horizontal scalability.
- **database-administrator** — Manages database systems including schema design, query optimization, replication, backup strategies, and performance tuning for production workloads.
- **database-engineer** — Database architecture and design specialist.
- **database-optimizer** _(model: sonnet)_ — Optimizes database query performance, indexing strategies, and data access patterns to reduce latency and improve throughput for production workloads.
- **microservices-architect** — Designs distributed system architecture, decomposes monolithic applications into microservices, and establishes inter-service communication patterns.
- **microservices-evaluator** _(model: sonnet)_ — Evalúa arquitectura de microservicios: boundaries de servicio, aislamiento de datos, comunicación inter-servicio, resiliencia y deployability independiente.

```ts
Agent(subagent_type: "api-design-evaluator", model: "opus", prompt: "...")
```

### Data, AI & ML (4 agentes)

- **ai-engineer** _(model: sonnet)_ — Builds AI-powered applications integrating LLMs, embeddings, RAG pipelines, and agent frameworks with focus on reliability and production deployment.
- **ml-engineer** _(model: sonnet)_ — Develops machine learning models including data preprocessing, feature engineering, model training, evaluation, and optimization for production readiness.
- **mlops-engineer** _(model: sonnet)_ — Designs and implements ML operations pipelines including model training, versioning, deployment, monitoring, and automated retraining workflows.
- **prompt-engineer** _(model: sonnet)_ — Designs and optimizes prompts for LLMs including system prompts, few-shot examples, chain-of-thought patterns, and evaluation frameworks.

```ts
Agent(subagent_type: "ai-engineer", model: "opus", prompt: "...")
```

### DevOps & Infrastructure (7 agentes)

- **cloud-architect** _(model: sonnet)_ — Designs cloud-native architectures across AWS, GCP, or Azure with focus on scalability, cost optimization, security, and multi-region resilience.
- **devops-engineer** — Implements CI/CD pipelines, container orchestration, infrastructure automation, and production deployment strategies with monitoring and rollback capabilities.
- **iac-engineer** — Implements infrastructure-as-code using Terraform, Pulumi, or CloudFormation with focus on modularity, state management, and drift detection.
- **iac-strategist** — Designs infrastructure-as-code strategies, selects appropriate IaC tools, and establishes patterns for managing cloud infrastructure declaratively at scale.
- **kubernetes-specialist** — Manages Kubernetes clusters including deployment strategies, resource optimization, networking, security policies, and cluster operations at scale.
- **mcp-deployment-orchestrator** — MCP server deployment and operations specialist.
- **platform-engineer** — Builds internal developer platforms with self-service infrastructure, golden paths, service catalogs, and developer experience tooling.

```ts
Agent(subagent_type: "cloud-architect", model: "opus", prompt: "...")
```

### Documentation (1 agentes)

- **command-expert** _(model: sonnet)_ — CLI command development specialist for the claude-code-templates system.

```ts
Agent(subagent_type: "command-expert", model: "opus", prompt: "...")
```

### Frontend & UI (8 agentes)

- **design-bridge** _(model: sonnet)_ — Coordinates bidirectional design ↔ code workflows using available design tool MCPs (Pencil.dev, Penpot, Figma).
- **frontend-engineer** — Builds modern frontend applications with React, Vue, or Angular using component architecture, state management, and performance optimization patterns.
- **react-performance-optimizer** _(model: sonnet)_ — Specialist in React performance patterns, bundle optimization, and Core Web Vitals.
- **secure-by-design-evaluator** _(model: sonnet)_ — Evalúa codificación segura: validación de inputs, consultas parametrizadas, autenticación, protección de datos, logs seguros y gestión de errores.
- **ui-designer** — Creates user interface designs with focus on visual hierarchy, component systems, responsive layouts, and accessibility compliance.
- **ui-developer** — Implements user interface components with modern frontend frameworks, ensuring pixel-perfect rendering, accessibility, and cross-browser compatibility.
- **ui-ux-designer** _(model: sonnet)_ — Combines UI visual design with UX research to create user-centered interfaces balancing aesthetics, usability, and business objectives.
- **ux-researcher** _(model: opus)_ — Conducts user experience research including usability testing, user interviews, journey mapping, and data-driven design recommendations.

```ts
Agent(subagent_type: "design-bridge", model: "opus", prompt: "...")
```

### Process & Orchestration (4 agentes)

- **commit-guardian** _(model: sonnet)_ — Verificación pre-commit con protocolo de 10 checks automáticos.
- **git-flow-manager** — Git Flow workflow manager.
- **sdk-config** _(model: sonnet)_ — Configures ASD SDK settings, agent registries, hooks, and project initialization parameters for development workflow optimization.
- **workflow-orchestrator** _(model: sonnet)_ — Diseña y ejecuta workflows de negocio complejos con saga patterns, state machines y recovery.

```ts
Agent(subagent_type: "commit-guardian", model: "opus", prompt: "...")
```

### Quality & Testing (10 agentes)

- **accessibility-tester** — Tests web applications for WCAG 2.1 AA/AAA compliance, identifies accessibility barriers, and provides remediation guidance for inclusive user experiences.
- **code-reviewer** _(model: sonnet)_ — Revisión formal de código enfocada en calidad, seguridad, rendimiento y mantenibilidad.
- **debugger** _(model: sonnet)_ — Systematically diagnoses and resolves software bugs using debugging tools, log analysis, reproduction strategies, and root cause analysis techniques.
- **penetration-tester** — Conducts security penetration testing including OWASP Top 10 assessment, API security testing, and infrastructure vulnerability scanning with remediation plans.
- **playwright-tester** _(model: sonnet)_ — Testing E2E con Playwright: exploración, generación de tests, ejecución y refinamiento.
- **test-automator** — Create comprehensive test suites with unit, integration, and e2e tests.
- **test-engineer** _(model: sonnet)_ — Test automation and quality assurance specialist.
- **test-generator** _(model: sonnet)_ — Genera test cases comprensivos analizando código y patrones existentes del proyecto.
- **test-runner** _(model: sonnet)_ — Ejecuta tests, analiza resultados, diagnostica fallos y propone fixes accionables.
- **testing-strategy-evaluator** _(model: sonnet)_ — Evalúa estrategia de testing: pirámide de testing, TDD, pruebas de contrato y análisis SAST.

```ts
Agent(subagent_type: "accessibility-tester", model: "opus", prompt: "...")
```

### Security & Compliance (3 agentes)

- **compliance-auditor** _(model: sonnet)_ — Auditoría de cumplimiento regulatorio: GDPR, HIPAA, PCI DSS, SOC 2, SARLAFT.
- **security-analyst** — Performs comprehensive security analysis including threat modeling, vulnerability assessment, and security architecture review for applications and infrastructure.
- **security-scanner** _(model: sonnet)_ — Ejecuta escaneo de vulnerabilidades local con Semgrep CE (SAST), Bearer CLI (PII/data flow) y Trivy (SCA/secrets) sobre contenedores Docker/Podman.

```ts
Agent(subagent_type: "compliance-auditor", model: "opus", prompt: "...")
```

### Uncategorized (33 agentes)

- **ci-cd-pipeline-evaluator** _(model: sonnet)_ — Evalúa calidad de pipelines CI/CD: stages, test gates, security scanning, deployment strategies, rollback, artifact management y pipeline performance.
- **clean-code-evaluator** _(model: sonnet)_ — Evalúa calidad de código limpio: naming, SRP funcional, complejidad ciclomática, duplicidad, código muerto y estándares.
- **code-explorer** — Deeply analyzes existing codebase features by tracing execution paths, mapping architecture layers, understanding patterns and abstractions, and documenting dependencies to inform…
- **codebase-pattern-finder** _(model: sonnet)_ — Documentalista de patrones existentes en el codebase.
- **context7** — Expert in latest library versions, best practices, and correct syntax using up-to-date documentation
- **cqrs-evaluator** _(model: sonnet)_ — Evalúa principios de CQRS: segregación de comandos y queries, modelos de lectura/escritura independientes y consistencia eventual.
- **ddd-solid-evaluator** _(model: sonnet)_ — Evalúa principios de DDD (Bounded Contexts, Aggregates, Value Objects, Domain Events) y SOLID (SRP, OCP, LSP, ISP, DIP).
- **error-coordinator** — Coordinates error handling across distributed systems, correlates failures, manages incident response workflows, and establishes error recovery patterns.
- **error-detective** _(model: sonnet)_ — Investigates and diagnoses complex runtime errors, stack traces, and system failures by analyzing logs, code paths, and environmental factors.
- **event-driven-evaluator** _(model: sonnet)_ — Evalúa arquitectura event-driven: event sourcing, pub/sub, SAGA patterns, idempotencia, schemas de eventos y dead letter queues.
- **implementation-plan** _(model: sonnet)_ — Genera planes de implementación estructurados, determinísticos y ejecutables por agentes o humanos.
- **initializer** _(model: opus)_ — Initializes new projects with ASD SDK scaffolding, configuration files, agent setup, and development workflow automation.
- **markdown-syntax-formatter** _(model: sonnet)_ — Markdown formatting specialist.
- **mcp-developer** — Develops Model Context Protocol servers and integrations enabling LLM tools to interact with external services, APIs, and data sources.
- **mcp-expert** _(model: sonnet)_ — Model Context Protocol (MCP) integration specialist for the cli-tool components system.
- **monitoring-specialist** _(model: sonnet)_ — Monitoring and observability infrastructure specialist.
- **monorepo-structure-evaluator** _(model: sonnet)_ — Evalúa estructura de monorepo: workspaces, dependency graph, shared code, build orchestration, code ownership y deployability independiente.
- **multi-agent-coordinator** _(model: sonnet)_ — Coordinates multiple agents working on related tasks, manages dependencies between agent outputs, and ensures consistent cross-agent deliverables.
- **nextjs-developer** — Builds production Next.js 14+ applications with App Router, server components, and advanced performance optimization including Core Web Vitals tuning.
- **performance-monitor** — Establishes observability infrastructure to track system metrics, detect performance anomalies, and optimize resource usage across distributed environments.
- **performance-profiler** _(model: sonnet)_ — Análisis de rendimiento: profiling de CPU, memoria, queries, network y Core Web Vitals.
- **planner** _(model: sonnet)_ — Genera planes de implementación estructurados y determinísticos antes de codificar.
- **principal-engineer** _(model: sonnet)_ — Guía de ingeniería a nivel principal: excelencia técnica, liderazgo y pragmatismo.
- **refactoring-specialist** _(model: sonnet)_ — Transformaciones seguras de código: detecta smells, aplica patrones clean code y garantiza zero behavior changes.
- **report-generator** _(model: sonnet)_ — Generates structured reports from data analysis including formatting, visualization recommendations, and executive summary creation.
- **resilience-observability-evaluator** _(model: sonnet)_ — Evalúa resiliencia y observabilidad: logging estructurado, métricas, trazabilidad distribuida, retries, timeouts, fallbacks y gestión de dependencias.
- **sdd-spec-writer** — Specification writer for Spec-Driven Development (SDD) — creates executable specifications that serve as unambiguous contracts for both human developers and AI agents.
- **spring-boot-engineer** — Builds production Spring Boot applications with focus on auto-configuration, security, data access, and cloud-native deployment patterns.
- **task-distributor** — Distributes tasks across multiple agents or workers, manages queues, and balances workloads to maximize throughput while respecting priorities and deadlines.
- **tdd-green** _(model: sonnet)_ — Implementa el código mínimo necesario para hacer pasar el test que falla, sin over-engineering.
- **tdd-red** _(model: sonnet)_ — Guía el desarrollo test-first escribiendo tests que describen el comportamiento deseado ANTES de que exista implementación.
- **technical-debt-manager** _(model: sonnet)_ — Identifica, cuantifica, prioriza y genera roadmaps de reducción de deuda técnica.
- **typescript-pro** _(model: sonnet)_ — Especialista en sistema de tipos avanzado de TypeScript: generics, conditional types, mapped types, full-stack type safety.

```ts
Agent(subagent_type: "ci-cd-pipeline-evaluator", model: "opus", prompt: "...")
```

## Skills disponibles (35)

- **Agent Development** — This skill should be used when the user asks to "create an agent", "add an agent", "write a subagent", "agent frontmatter", "when to use description", "agent examples", "agent too…
- **audit-deps** — Audit Node.js dependencies for vulnerabilities, outdated packages, and CVEs.
- **brainstorming** — You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior.
- **clean-code** — Pragmatic coding standards - concise, direct, no over-engineering, no unnecessary comments.
- **coverage-report** — Run test coverage, parse coverage-summary.json, identify hotspots without coverage, and suggest missing tests.
- **deploy-checklist** — Pre-deployment validation and session-end protocol.
- **devops-iac-engineer** — Implements infrastructure as code using Terraform, Kubernetes, and cloud platforms.
- **dispatching-parallel-agents** — Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
- **docx** — Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files).
- **extract-contracts** — Extract OpenAPI/GraphQL contracts from source code (controllers, DTOs, resolvers) and update API_CONTRACTS.md.
- **figma-design** — Design ↔ code workflow using Figma MCP.
- **finishing-a-development-branch** — Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for…
- **multi-dispatch** — Inyecta estrategia de ejecución multi-agente en planes y work items.
- **multi-dispatch-pro** — Orquestacion multi-agente avanzada con flujos por tipo de WI, dispatch manifests YAML, 7 roles con prompts, protocolo Excalidraw, y limites de concurrencia por tier.
- **orchestrator-runtime** — Runtime orchestration layer — state machine, mixed agent dispatch (ASD + native), skill auto-loading, progress tracking, and human-in-the-loop checkpoints for ASD SDK v3.4.1
- **pencil-design** — Bidirectional design ↔ code workflow using Pencil.dev MCP.
- **penpot-design** — Bidirectional design ↔ code workflow using Penpot MCP.
- **plan-mode** — Plan Model — Entra en modo planificación con Opus 4.6.
- **react-best-practices** — Comprehensive React and Next.js performance optimization guide with 40+ rules for eliminating waterfalls, optimizing bundles, and improving rendering.
- **receiving-code-review** — Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verificat…
- **requesting-code-review** — Use when completing tasks, implementing major features, or before merging to verify work meets requirements
- **skill-forge** — Wizard interactivo para crear skills ASD.
- **subagent-driven-development** — Use when executing implementation plans with independent tasks in the current session
- **systematic-debugging** — Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
- **tailwind-patterns** — Tailwind CSS v4 principles.
- **test-driven-development** — Use when implementing any feature or bugfix, before writing implementation code
- **test-harness** — Sets up and enforces test infrastructure for the project.
- **using-git-worktrees** — Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection…
- **using-superpowers** — Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
- **verification-before-completion** — Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any suc…
- **verify-step** — Use after completing a step implementation to intelligently evaluate acceptance criteria and update claude-progress.json.
- **vulnerability-scanner** — Advanced vulnerability analysis principles.
- **webapp-testing** — Toolkit for interacting with and testing local web applications using Playwright.
- **writing-plans** — Use when you have a spec or requirements for a multi-step task, before touching code
- **writing-skills** — Use when creating new skills, editing existing skills, or verifying skills work before deployment

## Hooks activos (15)

| Hook | Evento | Función |
|------|--------|---------|
| `agent-lifecycle.sh` | desconocido | ASD SDK v3.17.0 — Agent Lifecycle Hook |
| `agent-pool.sh` | PreToolUse matcher: Agent | ASD SDK v3.17.0 — Agent Pool Semaphore Hook (PreToolUse matcher: Agent) |
| `claude-md-budget.sh` | PreToolUse matcher: Edit\|Write | ASD SDK v3.17.0 — CLAUDE.md Budget Enforcement Hook (PreToolUse matcher: Edit\|Write) |
| `mcp-health-check.sh` | desconocido | ASD SDK v3.17.0 — MCP Health Check Hook |
| `observe.sh` | desconocido | ASD SDK v3.17.0 — Observability Hook |
| `output-optimizer.sh` | PreToolUse matcher: Bash | ASD SDK — Output Optimizer Hook (PreToolUse matcher: Bash) |
| `plan-detector.sh` | desconocido | plan-detector.sh — UserPromptSubmit hook |
| `post-verify.sh` | desconocido | ASD SDK v3.17.0 — Post-Verify Hook |
| `pre-agent-dispatch.sh` | PreToolUse matcher: Agent | ASD SDK v3.17.0 — Pre-Agent Dispatch Hook (PreToolUse matcher: Agent) |
| `pre-commit-agent-budget.sh` | desconocido | ASD SDK v3.16.0 — Agent Description Budget Hook |
| `pre-direct-edit.sh` | PreToolUse payload | pre-direct-edit.sh — PreToolUse matcher: Edit\|Write |
| `probe-payload.sh` | desconocido | probe-payload.sh — Diagnostic hook (NOT registered by default) |
| `progress-tracker.sh` | PostToolUse matcher: Bash | ASD SDK v3.17.0 — Progress Tracker Hook |
| `session-init.sh` | desconocido | ASD SDK v3.17.0 — Session Init Hook |
| `session-summary.sh` | desconocido | ASD SDK v3.17.0 — Session Summary Hook |

## Comandos slash disponibles (11)

- `/fallback` — Activa modo resiliencia cuando Claude Code CLI no está disponible (rate limit, outage, tokens agotados)
- `/greenfield-init` — Protocolo de inicio para proyectos nuevos — entrevista, brief y propuesta de arquitectura
- `/init` — Protocolo de inicio de sesión ASD — carga contexto, valida config y establece estado inicial
- `/observe` — Genera dashboard de observabilidad con métricas de sesión, agentes y herramientas
- `/plan` — Entra en modo planificación con Opus 4.6 — analiza, estructura y diseña antes de ejecutar
- `/release` — Validate and create a semver release — bumps version, updates changelog, creates git tag
- `/sdk-help` — Agente Q&A de documentación del ASD SDK — responde preguntas sobre uso, config y troubleshooting
- `/skill-forge` — Wizard interactivo para crear skills ASD — entrevista de 5 pasos, genera SKILL.md e integra en el ecosistema SDK (manifest, checksums, templates, CHANGELOG)
- `/verify-step` — Verificación post-step — evalúa acceptance criteria, ejecuta tests y actualiza progreso
- `/work-item` — Gestiona work items del proyecto — entry point obligatorio para desarrollo con dispatch forzado de agentes
- `/workspace-bootstrap` — Bootstrap paralelo multi-repo — inicializa múltiples repos con asd-init simultáneamente

---

*Regenerado en: 2026-05-21T22:36:29.097Z*
