# Plan: LegalMove — Análisis Multimodal de Cambios Contractuales

> **Fecha:** 2026-05-21
> **Estado:** PENDIENTE APROBACION
> **Branch:** `feat/legalmove-contract-analyzer`
> **Tipo:** feature (greenfield)
> **Complejidad:** alta (4 WIs, 16 steps)
> **Estrategia:** `/multi-dispatch-pro` flujo feature

---

## Contexto del Proyecto

**Empresa ficticia:** LegalMove
**Problema:** Automatizar la comparación entre contratos originales y sus adendas/enmiendas, extrayendo cambios legales de forma estructurada.

**Pipeline:**
```
2 imágenes (contrato + adenda)
  → GPT-4o Vision (parse a texto)
    → ContextualizationAgent (mapa semántico)
      → ExtractionAgent (detecta cambios)
        → Pydantic validation (JSON)
          → Langfuse (trazabilidad completa)
```

## Stack Técnico (FIJO — no negociable)

| Tecnología | Uso |
|------------|-----|
| Python 3.11+ | Lenguaje base |
| OpenAI GPT-4o Vision | Parsing multimodal de imágenes → texto |
| LangChain | Orquestación de los 2 agentes colaborativos |
| Pydantic v2 | Validación y estructura del output final |
| Langfuse | Trazabilidad del workflow (spans jerárquicos) |
| python-dotenv | Manejo seguro de variables de entorno |

## Estructura de Entregables

```
proyecto-m4-ludwing/
├── src/
│   ├── __init__.py
│   ├── main.py                          # Entry point CLI
│   ├── image_parser.py                  # GPT-4o Vision + base64
│   ├── models.py                        # ContractChangeOutput (Pydantic)
│   └── agents/
│       ├── __init__.py
│       ├── contextualization_agent.py   # Agente 1: Analista Senior
│       └── extraction_agent.py          # Agente 2: Auditor Legal
├── data/test_contracts/
│   ├── README.md
│   ├── par1_simple_original.png
│   ├── par1_simple_amendment.png
│   ├── par2_complex_original.png
│   └── par2_complex_amendment.png
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

---

## Work Items

### WI-01: Scaffold + Modelos Base

**Objetivo:** Fundación del proyecto — sin esto nada compila
**Phase multi-dispatch-pro:** BUILD (Worktree A)
**Agente:** backend-developer (ASD) / general-purpose (nativo)
**Modelo:** Sonnet 4.6

| # | Step | Descripción | Archivos |
|---|------|-------------|----------|
| 1 | Scaffold proyecto | Estructura dirs, `.gitignore`, `requirements.txt` (versiones fijadas), `.env.example` (4 vars) | `requirements.txt`, `.env.example`, `.gitignore`, `src/__init__.py`, `src/agents/__init__.py` |
| 2 | Modelo Pydantic | `ContractChangeOutput` + `ClauseChange`, field descriptions, validators, manejo `ValidationError` | `src/models.py` |
| 3 | Image Parser | `parse_contract_image()`: validación path, base64, GPT-4o Vision, prompt jerárquico, retries | `src/image_parser.py` |
| 4 | Test manual parser | Probar con 1 imagen, validar texto con estructura de cláusulas | Ejecución manual |

**Acceptance Criteria:**
- [ ] `pip install -r requirements.txt` sin errores
- [ ] `.env.example` con 4 variables (OPENAI_API_KEY, LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY, LANGFUSE_HOST)
- [ ] `ContractChangeOutput.model_validate()` acepta JSON válido, rechaza inválido
- [ ] `parse_contract_image("path/img.png")` retorna texto con cláusulas identificables

---

### WI-02: Agentes LangChain Colaborativos

**Objetivo:** Core del sistema — 2 agentes + handoff
**Phase multi-dispatch-pro:** BUILD (Worktree B, después de merge WI-01)
**Agente:** backend-developer (ASD)
**Modelo:** Sonnet 4.6

| # | Step | Descripción | Archivos |
|---|------|-------------|----------|
| 1 | ContextualizationAgent | LangChain agent, system prompt "Analista Legal Senior", produce mapa semántico | `src/agents/contextualization_agent.py` |
| 2 | ExtractionAgent | LangChain agent, system prompt "Auditor Legal", structured output Pydantic | `src/agents/extraction_agent.py` |
| 3 | Handoff contract | Flujo de traspaso Agent1 → Agent2, validación del mapa contextual | Ajustes en agents |
| 4 | Test agentes E2E | Pipeline completo imagen → parse → Agent1 → Agent2 → JSON validado | Ejecución manual |

**Acceptance Criteria:**
- [ ] ContextualizationAgent genera mapa con cláusulas identificadas
- [ ] ExtractionAgent recibe mapa + textos, genera lista de cambios
- [ ] Handoff explícito: Agent2 usa output de Agent1
- [ ] JSON final pasa `ContractChangeOutput.model_validate()`

---

### WI-03: Observabilidad Langfuse + Pipeline Integrado

**Objetivo:** Trazabilidad completa + entry point main.py
**Phase multi-dispatch-pro:** INTEGRATE (secuencial, requiere WI-01 + WI-02)
**Agente:** backend-developer (ASD)
**Modelo:** Sonnet 4.6

| # | Step | Descripción | Archivos |
|---|------|-------------|----------|
| 1 | Instrumentación Langfuse | Cliente Langfuse, traza padre `contract_analysis`, spans: `image_parsing`, `agent.contextualization`, `agent.extraction`, `validation` | `src/main.py`, ajustes en parser y agents |
| 2 | Pipeline main.py | CLI argparse: 2 paths, orquesta parse → Agent1 → Agent2 → validate → JSON | `src/main.py` |
| 3 | Error handling | Imagen no existe, formato inválido, API timeout, ValidationError — todo logueado en spans | `src/main.py`, `src/image_parser.py` |
| 4 | Test E2E 2 pares | Ejecutar con Par 1 (simple) + Par 2 (complejo), verificar Langfuse dashboard | Ejecución + ajustes |

**Acceptance Criteria:**
- [ ] `python src/main.py img1.png img2.png` produce JSON válido
- [ ] Dashboard Langfuse: traza padre + 4 spans hijos jerárquicos
- [ ] Cada span registra input, output, tokens, latencia
- [ ] Errores de API manejados sin crash

---

### WI-04: Assets de Prueba + Documentación + Demo-Ready

**Objetivo:** Entregables finales para evaluación
**Phase multi-dispatch-pro:** BUILD (step 1 paralelo) + DOCUMENT (steps 2-4)
**Agente:** general-purpose (nativo) + documentation-engineer (ASD)
**Modelo:** Sonnet 4.6

| # | Step | Descripción | Archivos |
|---|------|-------------|----------|
| 1 | Contratos de prueba | 2 pares (4 imágenes). Par 1: cambio simple. Par 2: cambio complejo. README explicativo | `data/test_contracts/` |
| 2 | README raíz | Diagrama Mermaid, setup (clone→venv→pip→.env→run), justificación técnica | `README.md` |
| 3 | Pulido y validación | No keys hardcodeadas, imports correctos, estructura = entregables, lint | Todos `src/` |
| 4 | Dry run demo | Simular defensa 30 min: 2 casos + dashboard Langfuse + Q&A | Ejecución completa |

**Acceptance Criteria:**
- [ ] 2 pares de contratos con README
- [ ] README raíz con diagrama, setup 5 pasos, justificación técnica
- [ ] `detect-secrets scan` limpio
- [ ] Demo 2 casos sin errores E2E

---

## Estrategia Multi-Dispatch-Pro — Flujo Feature

### Phase 1: PLAN (Opus 4.6)
- **Agente:** implementation-plan (T1)
- **Acción:** Fijar contratos de interfaz entre módulos
  - Schema exacto de `ContractChangeOutput` y `ClauseChange`
  - Formato output del ContextualizationAgent
  - Naming de spans Langfuse
  - System prompts skeleton
- **Gate:** Contratos aprobados → Phase 2

### Phase 2: BUILD PARALELO (Sonnet 4.6)
- **Worktree A (secuencial):** WI-01 completo → scaffold + models + parser
  - Se mergea PRIMERO (WI-02 depende de models.py)
- **Worktree B (después merge A):** WI-02 completo → agentes LangChain
- **Worktree C (paralelo con B):** WI-04 step 1 → assets de prueba
- **Gate:** 3 worktrees mergeados sin conflictos

### Phase 3: INTEGRATE (Sonnet 4.6)
- **Secuencial:** WI-03 completo → main.py + Langfuse + error handling
- Requiere WI-01 + WI-02 + WI-04.step1 mergeados
- **Gate:** `python src/main.py` ejecuta sin errores con ambos pares

### Phase 4: VERIFY (Sonnet 4.6)
- Validar contra rúbrica punto por punto:
  - 1.1 Parsing (15pts) — jerarquía preservada
  - 1.2 Agentes (15pts) — handoff funcional
  - 1.3 Pydantic (10pts) — validate + reject
  - 2.1 Prompting (15pts) — especializados
  - 2.2 Errores (10pts) — robusto
  - 3.1 Langfuse (15pts) — spans jerárquicos
- **Gate:** Todos criterios en "Excelente"

### Phase 5: DOCUMENT (Sonnet 4.6)
- WI-04 steps 2-4: README + pulido + dry run demo
- **Gate:** README completo, secrets limpio, demo fluye

## Orden de Ejecución

| Orden | WI / Phase | Modelo | Paralelo con |
|-------|-----------|--------|-------------|
| 1 | Phase 1: Plan interfaces | Opus 4.6 | — |
| 2 | WI-01: Scaffold + Models + Parser | Sonnet 4.6 | — |
| 3a | WI-02: Agentes LangChain | Sonnet 4.6 | 3b |
| 3b | WI-04.step1: Assets de prueba | Sonnet 4.6 | 3a |
| 4 | WI-03: Pipeline + Langfuse | Sonnet 4.6 | — |
| 5 | Verify rúbrica | Sonnet 4.6 | — |
| 6 | WI-04.steps2-4: README + Demo | Sonnet 4.6 | — |

## Riesgos y Mitigaciones

| Riesgo | Mitigación |
|--------|-----------|
| GPT-4o Vision pierde jerarquía en contratos complejos | Prompt de parsing explícito pidiendo Markdown con headers por cláusula |
| LangChain agentes alucinan cambios no presentes | ExtractionAgent recibe ambos textos + mapa; structured output con Pydantic |
| Langfuse spans planos (penaliza rúbrica 3.1) | Usar `@observe()` decorators + jerarquía parent/child explícita |
| Costos OpenAI durante desarrollo | Cache de respuestas Vision en `data/.cache/` |
| Corrector pide cambios on-the-fly en defensa | Tener 3+ pares de contratos preparados |

## Rúbrica de Evaluación (referencia rápida)

| Criterio | Peso | Target |
|----------|------|--------|
| 1.1 Parsing Multimodal | 15pts | Excelente |
| 1.2 Arquitectura 2 Agentes | 15pts | Excelente |
| 1.3 Validación Pydantic | 10pts | Excelente |
| 2.1 Calidad Prompting | 15pts | Excelente |
| 2.2 Gestión API/Errores | 10pts | Excelente |
| 3.1 Trazabilidad Langfuse | 15pts | Excelente |
| 4.1 Estructura + README | 10pts | Excelente |
| 5.1 Defensa en vivo | 10pts | Excelente |
| **TOTAL** | **100pts** | **100/100** |

---

> *Plan generado: 2026-05-21 | Pendiente aprobación del usuario*
