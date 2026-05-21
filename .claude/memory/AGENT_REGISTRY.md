# AGENT_REGISTRY.md
> Registro de agentes activos — ASD SDK v3.18.0

## Agentes del Sistema (Grupo 9)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| initializer | STANDBY | filesystem_read, git_read | — |
| context-collector | STANDBY | filesystem_read, git_read | — |
| sdk-config | STANDBY | filesystem_read, filesystem_write | — |
| orchestrator | STANDBY | filesystem_read, filesystem_write, git_read, git_write, mcp_execute | — |
| git-workflow-manager | STANDBY | filesystem_read, git_read, git_write | — |
| docs-writer | STANDBY | filesystem_read, filesystem_write, git_read | — |

## Agentes de Análisis (Grupo 1)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| architecture-master | STANDBY | filesystem_read, filesystem_write, git_read, git_write, mcp_execute | — |
| code-analyzer | STANDBY | filesystem_read, git_read | — |

## Agentes Frontend (Grupo 2)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| ux-researcher | STANDBY | filesystem_read, git_read | — |
| ui-developer | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |
| frontend-engineer | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |

## Agentes Backend (Grupo 3)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| backend-architect | STANDBY | filesystem_read, git_read, mcp_execute | — |
| backend-developer | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |
| integration-specialist | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |

## Agentes Data e Infraestructura (Grupo 4)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| database-engineer | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |
| devops-engineer | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |
| iac-engineer | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |
| kubernetes-specialist | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |

## Agentes Cloud (Grupo 5)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| cloud-architect | STANDBY | filesystem_read, git_read, mcp_execute | — |
| iac-strategist | STANDBY | filesystem_read, git_read, mcp_execute | — |

## Agentes Calidad y Seguridad (Grupo 6)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| sonarqube-reviewer | STANDBY | filesystem_read, git_read, mcp_execute | — |
| security-analyst | STANDBY | filesystem_read, git_read, mcp_execute | — |
| qa-engineer | STANDBY | filesystem_read, git_read, mcp_execute | — |

## Agentes Testing (Grupo 7)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| backend-unit-tester | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |
| frontend-unit-tester | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |
| playwright-automation | STANDBY | filesystem_read, filesystem_write, git_read, git_write, bash_execute, mcp_execute | — |

## Agentes Legacy (Grupo 8)

| Agente | Estado | Capability | Última activación |
|--------|--------|-----------|-------------------|
| architecture-detective | STANDBY | filesystem_read, git_read | — |
| dependency-auditor | STANDBY | filesystem_read, git_read | — |
| test-coverage-analyst | STANDBY | filesystem_read, git_read | — |
| api-contract-extractor | STANDBY | filesystem_read, git_read | — |

---
*Estados válidos: STANDBY | ACTIVE | BLOCKED | DONE | FAILED*
