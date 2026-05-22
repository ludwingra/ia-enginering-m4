"""
ContractAnalysisPipeline — Orquestador del Pipeline LegalMove

Orquesta el flujo completo de análisis contractual entre los dos agentes:

    ContextualizationAgent.analyze() → semantic_map (str)
                                    ↓  [HANDOFF]
    ExtractionAgent.extract(semantic_map) → dict
                                    ↓
    ContractChangeOutput.model_validate(dict) → ContractChangeOutput

El semantic_map producido por el Analista Legal Senior (Agent 1) se pasa
explícitamente al Auditor Legal (Agent 2) como contexto enriquecido, siguiendo
el contrato de handoff definido en la arquitectura del sistema.

Cuando se provee un ``trace`` de Langfuse al método ``run()``, el pipeline
crea internamente child spans para cada paso, manteniendo la jerarquía de
trazabilidad sin exponer lógica de instrumentación al caller.
"""

import json
import logging
import time
from typing import TYPE_CHECKING, Any

from pydantic import ValidationError

from src.agents.contextualization_agent import ContextualizationAgent
from src.agents.extraction_agent import ExtractionAgent
from src.models import ContractChangeOutput

if TYPE_CHECKING:
    pass  # Langfuse trace type — imported lazily to avoid hard dependency at module level

logger = logging.getLogger(__name__)


class ContractAnalysisPipeline:
    """
    Pipeline de análisis contractual que orquesta el flujo entre ambos agentes.

    Flujo de ejecución:
        1. ContextualizationAgent.analyze() → genera el mapa semántico (handoff)
        2. ExtractionAgent.extract()        → extrae cambios usando el mapa semántico
        3. ContractChangeOutput.model_validate() → valida el output con Pydantic

    El semantic_map actúa como el contrato de handoff entre ambos agentes:
    Agent 1 lo produce como str Markdown, Agent 2 lo recibe como contexto privilegiado.
    """

    def __init__(
        self,
        model_name: str = "gpt-4o",
        temperature: float = 0.0,
        api_key: str | None = None,
    ) -> None:
        """
        Inicializa el pipeline instanciando ambos agentes con los mismos parámetros.

        Args:
            model_name: Identificador del modelo OpenAI a usar en ambos agentes
                        (default: "gpt-4o").
            temperature: Temperatura de sampleo para ambos agentes. 0.0 garantiza
                         salidas deterministas, recomendado para análisis legal.
            api_key: API key de OpenAI. Si se omite, se usa la variable de entorno
                     OPENAI_API_KEY.
        """
        self._model_name = model_name
        self._contextualization_agent = ContextualizationAgent(
            model_name=model_name,
            temperature=temperature,
            api_key=api_key,
        )
        self._extraction_agent = ExtractionAgent(
            model_name=model_name,
            temperature=temperature,
            api_key=api_key,
        )

    def run(
        self,
        original_text: str,
        amendment_text: str,
        trace: Any = None,
    ) -> ContractChangeOutput:
        """
        Ejecuta el pipeline completo y retorna el output validado con Pydantic.

        Flujo:
            Paso 1 — ContextualizationAgent genera el mapa semántico (str Markdown).
            Paso 2 — ExtractionAgent recibe el mapa semántico como handoff y extrae
                     los cambios contractuales (dict).
            Paso 3 — ContractChangeOutput.model_validate() valida el dict resultante.

        Args:
            original_text: Texto completo del contrato original.
            amendment_text: Texto completo de la adenda o enmienda contractual.
            trace: Objeto trace de Langfuse (opcional). Cuando se provee, el pipeline
                   crea child spans para cada paso con input, output y latency_ms.
                   Cuando es None el pipeline corre sin instrumentación (backward compatible).

        Returns:
            ContractChangeOutput validado con todos los cambios detectados.

        Raises:
            ValidationError: Si el dict producido por ExtractionAgent no cumple
                             el schema de ContractChangeOutput. Se re-raise con
                             mensaje descriptivo que incluye los errores de validación.
            ValueError: Si ExtractionAgent no puede extraer un JSON válido del LLM.
        """
        # ------------------------------------------------------------------
        # Paso 1: ContextualizationAgent genera el mapa semántico
        # ------------------------------------------------------------------
        logger.info("Paso 1/3 — ContextualizationAgent: generando mapa semántico...")

        span_ctx = None
        if trace is not None:
            span_ctx = trace.span(
                name="agent_contextualization",
                input={
                    "original_text_length": len(original_text),
                    "amendment_text_length": len(amendment_text),
                    "original_preview": original_text[:300],
                    "amendment_preview": amendment_text[:300],
                },
            )

        t0 = time.time()
        semantic_map: str = self._contextualization_agent.analyze(
            original_text=original_text,
            amendment_text=amendment_text,
        )
        latency_ms_ctx = round((time.time() - t0) * 1000, 2)
        logger.debug("Mapa semántico generado (%d chars).", len(semantic_map))

        if span_ctx is not None:
            span_ctx.end(
                output={
                    "semantic_map_length": len(semantic_map),
                    "semantic_map_preview": semantic_map[:400],
                },
                metadata={
                    "latency_ms": latency_ms_ctx,
                    "model": self._model_name,
                    "agent": "ContextualizationAgent",
                },
            )

        # ------------------------------------------------------------------
        # Paso 2: ExtractionAgent recibe el mapa semántico como handoff
        # ------------------------------------------------------------------
        logger.info(
            "Paso 2/3 — ExtractionAgent: extrayendo cambios usando el mapa semántico..."
        )

        span_ext = None
        if trace is not None:
            span_ext = trace.span(
                name="agent_extraction",
                input={
                    "original_text_length": len(original_text),
                    "amendment_text_length": len(amendment_text),
                    "semantic_map_length": len(semantic_map),
                    "semantic_map_preview": semantic_map[:400],
                },
            )

        t0 = time.time()
        result: dict = self._extraction_agent.extract(
            original_text=original_text,
            amendment_text=amendment_text,
            semantic_map=semantic_map,  # HANDOFF explícito: output de Agent 1 → input de Agent 2
        )
        latency_ms_ext = round((time.time() - t0) * 1000, 2)
        logger.debug("Dict de extracción obtenido con claves: %s.", list(result.keys()))

        if span_ext is not None:
            span_ext.end(
                output={
                    "result_keys": list(result.keys()),
                    "modified_clauses_count": len(result.get("modified_clauses", [])),
                    "result_preview": json.dumps(result)[:400],
                },
                metadata={
                    "latency_ms": latency_ms_ext,
                    "model": self._model_name,
                    "agent": "ExtractionAgent",
                },
            )

        # ------------------------------------------------------------------
        # Paso 3: Validar el dict con Pydantic
        # ------------------------------------------------------------------
        logger.info("Paso 3/3 — Validando output con ContractChangeOutput...")

        span_val = None
        if trace is not None:
            span_val = trace.span(
                name="validation",
                input={"raw_result": result},
            )

        t0 = time.time()
        try:
            validated_output = ContractChangeOutput.model_validate(result)
        except ValidationError as exc:
            error_detail = exc.json(indent=2)
            logger.error(
                "ValidationError al validar el output del pipeline.\n"
                "Errores de validación:\n%s\n"
                "Dict recibido: %s",
                error_detail,
                result,
            )
            raise ValidationError(
                exc.errors(),
                model=ContractChangeOutput,
            ) from exc
        latency_ms_val = round((time.time() - t0) * 1000, 2)

        if span_val is not None:
            span_val.end(
                output={
                    "total_changes": len(validated_output.modified_clauses),
                    "summary_preview": validated_output.summary_of_changes[:200],
                },
                metadata={
                    "latency_ms": latency_ms_val,
                    "schema": "ContractChangeOutput",
                    "validation": "pydantic_v2",
                },
            )

        logger.info(
            "Pipeline completado exitosamente. Cambios detectados: %d.",
            len(validated_output.modified_clauses),
        )
        return validated_output

    def run_raw(
        self,
        original_text: str,
        amendment_text: str,
    ) -> dict:
        """
        Ejecuta el pipeline y retorna el dict sin validar (útil para debugging).

        Sigue el mismo flujo de handoff que run() — el semantic_map de Agent 1
        se pasa explícitamente a Agent 2 — pero omite la validación Pydantic final,
        permitiendo inspeccionar el dict crudo para diagnóstico.

        Args:
            original_text: Texto completo del contrato original.
            amendment_text: Texto completo de la adenda o enmienda contractual.

        Returns:
            dict con la estructura de ContractChangeOutput sin validar con Pydantic.
            Útil para diagnosticar errores de schema o inspeccionar el output del LLM.

        Raises:
            ValueError: Si ExtractionAgent no puede extraer un JSON válido del LLM.
        """
        # Paso 1: ContextualizationAgent genera el mapa semántico
        logger.info(
            "[run_raw] Paso 1/2 — ContextualizationAgent: generando mapa semántico..."
        )
        semantic_map: str = self._contextualization_agent.analyze(
            original_text=original_text,
            amendment_text=amendment_text,
        )
        logger.debug("[run_raw] Mapa semántico generado (%d chars).", len(semantic_map))

        # Paso 2: ExtractionAgent recibe el mapa semántico como handoff
        logger.info(
            "[run_raw] Paso 2/2 — ExtractionAgent: extrayendo cambios (sin validación)..."
        )
        result: dict = self._extraction_agent.extract(
            original_text=original_text,
            amendment_text=amendment_text,
            semantic_map=semantic_map,  # HANDOFF explícito: output de Agent 1 → input de Agent 2
        )

        logger.debug(
            "[run_raw] Dict crudo obtenido con claves: %s.", list(result.keys())
        )
        return result
