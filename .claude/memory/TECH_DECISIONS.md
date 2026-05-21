# TECH_DECISIONS.md
> ADRs del proyecto — ASD SDK v3.18.0 | Última actualización: 2026-05-21T22:35:18.766Z

## ADR-001: IaC Tool
- **Decisión:** OpenTofu (default) — drop-in Terraform, licencia MPL 2.0, CNCF Sandbox
- **Estado:** [PENDIENTE — confirmar si aplica al proyecto]
- **Alternativas consideradas:** Terraform, Pulumi, CDK

## ADR-002: Estrategia de Branching
- **Decisión:** GitFlow simplificado — main + develop + feature/* + hotfix/*
- **Estado:** Propuesto
- **Convención de commits:** Conventional Commits (feat/fix/chore/docs/refactor)

## ADR-003: Modelo Claude Code
- **Sesión principal (orquestador):** Opus 4.6 — `model: "claude-opus-4-6"` en settings.json
- **Agentes de planificación:** Opus 4.6 — `Agent(model: "opus")` por invocación
- **Agentes de ejecución:** Sonnet 4.6 — `Agent(model: "sonnet")` por invocación
- **Estrategia:** Mixta — agentes ASD custom + agentes nativos de Claude Code como fallback
- **Estado:** Activo

## ADR-004: Análisis Estático
- **Decisión:** [PENDIENTE — SonarQube | SonarCloud | Ninguno]
- **Quality Gate mínimo:** 80% cobertura de líneas
- **Estado:** [PENDIENTE]

## ADR-005: Estrategia de Testing
- **Framework:** [PENDIENTE]
- **Cobertura mínima:** 80% por Work Item
- **E2E:** [PENDIENTE — Playwright | Cypress | Ninguno]
- **Estado:** [PENDIENTE]

## ADR-006: Cloud y Despliegue
- **Cloud provider:** [PENDIENTE — AWS | GCP | Azure | On-premise]
- **Estrategia:** [PENDIENTE — Blue/Green | Canary | Rolling]
- **Entornos:** [PENDIENTE — dev | staging | prod]
- **Estado:** [PENDIENTE]

---
*Nuevos ADRs: usar formato ADR-NNN con campos Decisión, Estado, Alternativas, Consecuencias.*
