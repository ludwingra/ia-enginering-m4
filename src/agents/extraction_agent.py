"""
ExtractionAgent — Auditor Legal

Segundo agente del pipeline LegalMove. Recibe el mapa semántico producido por el
ContextualizationAgent (Analista Legal Senior) junto con los textos originales, y
produce el output FINAL validado con Pydantic que cumple ContractChangeOutput.

Handoff: ContextualizationAgent.analyze() → str (mapa semántico Markdown)
                                          → ExtractionAgent.extract()
"""

import json
import re

from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

SYSTEM_PROMPT = """Eres un Auditor Legal con especialización en análisis de \
enmiendas contractuales y más de 15 años de experiencia en auditorías de \
contratos comerciales, laborales y de servicios profesionales.

Tu misión es recibir el mapa semántico elaborado por el Analista Legal Senior \
y los textos originales de ambos documentos, y producir un análisis JSON \
estructurado y exhaustivo de todos los cambios detectados.

## CONTEXTO DE TRABAJO

El Analista Legal Senior ya identificó y catalogó la estructura de ambos \
documentos, comparó cláusula por cláusula y priorizó los cambios más \
relevantes. Ese mapa semántico es tu fuente de verdad primaria. Úsalo como \
guía principal, y consulta los textos originales para extraer el texto \
literal exacto de cada cláusula modificada.

## INSTRUCCIONES DE ANÁLISIS

1. **Revisa el mapa semántico** para identificar TODAS las cláusulas \
   marcadas como MODIFICADA, ELIMINADA o NUEVA.
2. **Consulta los textos originales** para extraer los fragmentos literales \
   exactos del contrato original y de la adenda para cada cláusula afectada.
3. **No inventes cambios** que no estén explícitamente documentados en el \
   mapa semántico o en los textos originales.
4. **Asigna el nivel de significancia** (high/medium/low) basándote en el \
   impacto legal y económico del cambio, tal como lo priorizó el Analista.

## SCHEMA JSON REQUERIDO

Debes retornar EXACTAMENTE un objeto JSON con la siguiente estructura:

```json
{{
  "summary_of_changes": "<string — resumen ejecutivo conciso de todos los cambios detectados>",
  "modified_clauses": [
    {{
      "clause_id": "<string — identificador jerárquico de la cláusula, ej: '3.1', '5.2.a'>",
      "clause_title": "<string — título o nombre descriptivo de la cláusula>",
      "original_text": "<string — texto literal de la cláusula en el contrato original; vacío si es nueva>",
      "amended_text": "<string — texto literal de la cláusula en la adenda; vacío si fue eliminada>",
      "change_type": "<'added' | 'modified' | 'removed'>",
      "significance": "<'high' | 'medium' | 'low'>"
    }}
  ],
  "risk_assessment": "<string — evaluación profesional de los riesgos legales derivados de los cambios>"
}}
```

### Reglas de llenado de campos

- **summary_of_changes**: Síntesis ejecutiva de 2-4 oraciones. Menciona la \
  cantidad total de cambios y los más relevantes.
- **modified_clauses**: Array con UN objeto por cada cláusula afectada. \
  Incluye TODAS las cláusulas identificadas en el mapa semántico como \
  MODIFICADA, ELIMINADA o NUEVA. No omitas ninguna.
  - `clause_id`: Usa el identificador jerárquico exacto del mapa semántico.
  - `clause_title`: Nombre descriptivo claro de la cláusula.
  - `original_text`: Texto literal del contrato original. Deja vacío ("") \
    si la cláusula es nueva (change_type = "added").
  - `amended_text`: Texto literal de la adenda. Deja vacío ("") si la \
    cláusula fue eliminada (change_type = "removed").
  - `change_type`: Usa "added" para cláusulas nuevas, "modified" para \
    cláusulas existentes que cambiaron, "removed" para cláusulas eliminadas.
  - `significance`: Evalúa como "high" si tiene impacto económico o legal \
    mayor, "medium" si es relevante pero no crítico, "low" si es editorial \
    o menor.
- **risk_assessment**: Evaluación profesional de 3-6 oraciones. Identifica \
  los riesgos legales, económicos y operativos derivados del conjunto de \
  cambios. Prioriza los de mayor impacto.

## INSTRUCCIONES DE FORMATO

- Retorna SOLAMENTE el objeto JSON. Sin texto introductorio, sin explicaciones, \
  sin bloques de código markdown, sin comentarios.
- El JSON debe ser válido y parseable directamente con json.loads().
- Usa comillas dobles para todas las cadenas de texto.
- Escapa correctamente los caracteres especiales dentro de los strings \
  (comillas, saltos de línea, etc.)."""

HUMAN_TEMPLATE = """\
<mapa_semantico>
{semantic_map}
</mapa_semantico>

<contrato_original>
{original_text}
</contrato_original>

<adenda>
{amendment_text}
</adenda>

Genera el JSON de análisis de cambios siguiendo estrictamente el schema indicado."""


class ExtractionAgent:
    """
    Agente que actúa como Auditor Legal.

    Recibe el mapa semántico producido por el ContextualizationAgent, junto con
    los textos originales del contrato y la adenda, y produce un dict estructurado
    que cumple el schema de ContractChangeOutput, listo para ser validado con Pydantic.

    Handoff de entrada: output de ContextualizationAgent.analyze() (str Markdown)
    Output: dict validable con ContractChangeOutput(**result)
    """

    def __init__(
        self,
        model_name: str = "gpt-4o",
        temperature: float = 0.0,
        api_key: str | None = None,
    ) -> None:
        """
        Inicializa el agente con el modelo LangChain especificado.

        Args:
            model_name: Identificador del modelo OpenAI a usar (default: "gpt-4o").
            temperature: Temperatura de sampleo. 0.0 garantiza salidas deterministas,
                         esencial para auditoría legal donde la reproducibilidad importa.
            api_key: API key de OpenAI. Si se omite, se usa la variable de entorno
                     OPENAI_API_KEY.
        """
        llm_kwargs: dict = {"model": model_name, "temperature": temperature}
        if api_key is not None:
            llm_kwargs["api_key"] = api_key
        self._llm = ChatOpenAI(**llm_kwargs)

        self._prompt = ChatPromptTemplate.from_messages(
            [
                ("system", SYSTEM_PROMPT),
                ("human", HUMAN_TEMPLATE),
            ]
        )

        self._parser = StrOutputParser()

        # Chain: prompt → LLM → parser de string (el JSON parsing lo hacemos manualmente)
        self._chain = self._prompt | self._llm | self._parser

    def _extract_json_from_text(self, text: str) -> dict:
        """
        Intenta extraer un objeto JSON del texto cuando json.loads() falla directamente.

        Estrategia de fallback: busca el primer '{' y el último '}' para delimitar
        el bloque JSON embebido en texto con formato markdown u otro envoltorio.

        Args:
            text: Texto que contiene un JSON posiblemente rodeado de texto adicional.

        Returns:
            dict parseado del JSON extraído.

        Raises:
            ValueError: Si no se puede extraer un JSON válido del texto.
        """
        # Intento 1: extraer bloque JSON de fence markdown (```json ... ```)
        fence_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
        if fence_match:
            try:
                return json.loads(fence_match.group(1))
            except json.JSONDecodeError:
                pass

        # Intento 2: encontrar el primer '{' y el último '}' como delimitadores
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1 and end > start:
            candidate = text[start : end + 1]
            try:
                return json.loads(candidate)
            except json.JSONDecodeError as exc:
                raise ValueError(
                    f"No se pudo parsear el JSON extraído del texto. "
                    f"Fragmento intentado: {candidate[:200]}..."
                ) from exc

        raise ValueError(
            f"No se encontró ningún objeto JSON válido en el output del LLM. "
            f"Output recibido (primeros 500 chars): {text[:500]}"
        )

    def extract(
        self,
        original_text: str,
        amendment_text: str,
        semantic_map: str,
    ) -> dict:
        """
        Ejecuta el análisis de extracción y retorna el dict de cambios contractuales.

        Recibe el mapa semántico del ContextualizationAgent como contexto enriquecido
        (handoff entre agentes) junto con los textos originales para extracción literal.

        Args:
            original_text: Texto completo del contrato original.
            amendment_text: Texto completo de la adenda o enmienda contractual.
            semantic_map: Mapa semántico en Markdown producido por ContextualizationAgent.
                          Actúa como contexto privilegiado que guía la extracción.

        Returns:
            dict con la estructura de ContractChangeOutput:
            {
                "summary_of_changes": str,
                "modified_clauses": list[dict],  # cada dict cumple ClauseChange
                "risk_assessment": str,
            }
            Listo para ser validado con ContractChangeOutput(**result).

        Raises:
            ValueError: Si el output del LLM no contiene un JSON válido parseable.
        """
        raw_output: str = self._chain.invoke(
            {
                "semantic_map": semantic_map,
                "original_text": original_text,
                "amendment_text": amendment_text,
            }
        )

        # Intento primario: parsear directamente el output como JSON
        try:
            return json.loads(raw_output)
        except json.JSONDecodeError:
            pass

        # Fallback: extraer JSON embebido en texto adicional
        return self._extract_json_from_text(raw_output)
