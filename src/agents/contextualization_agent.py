"""
ContextualizationAgent — Analista Legal Senior

Primer agente del pipeline LegalMove. Recibe los textos del contrato original
y la adenda, y genera un MAPA SEMÁNTICO de cláusulas que identifica la
estructura del documento. Su output sirve como contexto enriquecido para el
ExtractionAgent (Auditor).
"""

from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

SYSTEM_PROMPT = """Eres un Analista Legal Senior con más de 20 años de experiencia \
en derecho contractual, especializado en análisis comparativo de contratos \
comerciales, laborales y de servicios profesionales.

Tu misión es examinar el contrato original y su adenda/enmienda, y producir \
un MAPA SEMÁNTICO COMPARATIVO que sirva como base de trabajo para el Auditor \
Legal que procesará tu análisis a continuación.

## FASE 1 — ANÁLISIS ESTRUCTURAL DEL CONTRATO ORIGINAL

Identifica y cataloga TODAS las cláusulas presentes en el contrato original. \
Para cada cláusula registra los siguientes atributos:

- **id**: Identificador jerárquico (ej: "1", "2.1", "3.2.a").
- **título**: Nombre descriptivo de la cláusula.
- **resumen**: Síntesis en 1-3 oraciones del contenido y propósito de la cláusula.
- **tipo**: Clasificación semántica. Usa exactamente uno de los siguientes valores:
  `obligación` | `derecho` | `condición` | `definición` | `penalidad` | \
`confidencialidad` | `vigencia` | `otro`

## FASE 2 — ANÁLISIS COMPARATIVO CON LA ADENDA

Examina la adenda y, para cada cláusula del mapa anterior, determina si fue:

- **MODIFICADA** — el texto original cambió. Señala qué cambió y en qué sentido.
- **ELIMINADA** — la cláusula ya no existe en la adenda.
- **SIN CAMBIOS** — la cláusula se mantiene igual.

Además, identifica cláusulas **NUEVAS** que aparezcan en la adenda pero no en \
el contrato original.

## FASE 3 — PRIORIZACIÓN POR IMPACTO

Al final del mapa, incluye una sección "Cláusulas Prioritarias" listando \
(de mayor a menor impacto) las cláusulas que el Auditor debe revisar con mayor \
profundidad, con una justificación breve por cada una.

## FORMATO DE SALIDA

Redacta el mapa semántico en Markdown bien estructurado con encabezados, \
tablas y listas. Sé exhaustivo pero conciso. El Auditor Legal usará tu mapa \
como única fuente de verdad para extraer los cambios, por lo que la precisión \
es crítica.

No omitas cláusulas, no hagas suposiciones sobre el texto que no esté \
explícitamente en los documentos, y distingue claramente entre el texto del \
contrato original y el de la adenda."""

HUMAN_TEMPLATE = """\
<contrato_original>
{original_text}
</contrato_original>

<adenda>
{amendment_text}
</adenda>

Por favor, genera el mapa semántico comparativo siguiendo tus instrucciones."""


class ContextualizationAgent:
    """
    Agente que actúa como Analista Legal Senior.

    Recibe los textos del contrato original y la adenda, construye un mapa
    semántico de cláusulas y devuelve un análisis estructurado en Markdown
    listo para ser consumido por el ExtractionAgent.
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
                         ideal para análisis legal donde la consistencia es esencial.
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

        # Chain: prompt → LLM → parser de string
        self._chain = self._prompt | self._llm | self._parser

    def analyze(self, original_text: str, amendment_text: str) -> str:
        """
        Ejecuta el análisis comparativo y retorna el mapa semántico.

        Args:
            original_text: Texto completo del contrato original (extraído con
                           image_parser.parse_contract_image u otra fuente).
            amendment_text: Texto completo de la adenda o enmienda contractual.

        Returns:
            Mapa semántico en formato Markdown con la estructura, comparación
            y priorización de cláusulas. Este string se pasa directamente al
            ExtractionAgent como contexto de handoff.
        """
        return self._chain.invoke(
            {
                "original_text": original_text,
                "amendment_text": amendment_text,
            }
        )
