"""
main.py — LegalMove Contract Analyzer — CLI Entry Point

Orquesta el pipeline completo de análisis contractual con instrumentación
Langfuse para trazabilidad jerárquica de spans:

    Trace padre: "contract_analysis"
      ├── Span: "image_parsing_original"
      ├── Span: "image_parsing_amendment"
      ├── Span: "agent_contextualization"
      ├── Span: "agent_extraction"
      └── Span: "validation"

Uso:
    python -m src.main original.png amendment.png [--model gpt-4o] [--output result.json]
"""

import argparse
import json
import sys
import time
from datetime import datetime, timezone

import pydantic
from dotenv import load_dotenv
from langfuse import Langfuse

from src.image_parser import parse_contract_image
from src.agents.contextualization_agent import ContextualizationAgent
from src.agents.extraction_agent import ExtractionAgent
from src.models import ContractChangeOutput, ContractMetadata, FullAnalysisResult


# ---------------------------------------------------------------------------
# Core pipeline with Langfuse instrumentation
# ---------------------------------------------------------------------------


def run_pipeline(
    original_path: str,
    amendment_path: str,
    model: str = "gpt-4o",
) -> FullAnalysisResult:
    """Execute the full contract analysis pipeline with Langfuse tracing.

    Creates a parent trace "contract_analysis" with 5 child spans that capture
    inputs, outputs, and latency_ms for each pipeline stage.

    Parameters
    ----------
    original_path:
        Filesystem path to the original contract image.
    amendment_path:
        Filesystem path to the amendment/addendum contract image.
    model:
        OpenAI model identifier to use for the agents (default: "gpt-4o").

    Returns
    -------
    FullAnalysisResult
        Pydantic-validated result combining metadata and the analysis output.

    Raises
    ------
    FileNotFoundError
        If either image path does not exist.
    ValueError
        If an image path has an unsupported extension or is invalid.
    pydantic.ValidationError
        If the extraction agent's output fails Pydantic schema validation.
    Exception
        For any other unexpected errors during pipeline execution.
    """
    load_dotenv()

    # Initialize Langfuse client (reads LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY,
    # and LANGFUSE_HOST from environment automatically)
    langfuse = Langfuse()

    # Create the parent trace for the entire pipeline run
    trace = langfuse.trace(
        name="contract_analysis",
        input={
            "original_path": original_path,
            "amendment_path": amendment_path,
            "model": model,
        },
    )

    try:
        # ------------------------------------------------------------------
        # Span 1 — image_parsing_original
        # ------------------------------------------------------------------
        span_parse_original = trace.span(
            name="image_parsing_original",
            input={"image_path": original_path},
        )
        t0 = time.time()
        original_text = parse_contract_image(original_path)
        latency_ms_1 = round((time.time() - t0) * 1000, 2)
        span_parse_original.end(
            output={"text_length": len(original_text), "text_preview": original_text[:200]},
            metadata={
                "latency_ms": latency_ms_1,
                "image_path": original_path,
                "chars_extracted": len(original_text),
            },
        )

        # ------------------------------------------------------------------
        # Span 2 — image_parsing_amendment
        # ------------------------------------------------------------------
        span_parse_amendment = trace.span(
            name="image_parsing_amendment",
            input={"image_path": amendment_path},
        )
        t0 = time.time()
        amendment_text = parse_contract_image(amendment_path)
        latency_ms_2 = round((time.time() - t0) * 1000, 2)
        span_parse_amendment.end(
            output={"text_length": len(amendment_text), "text_preview": amendment_text[:200]},
            metadata={
                "latency_ms": latency_ms_2,
                "image_path": amendment_path,
                "chars_extracted": len(amendment_text),
            },
        )

        # ------------------------------------------------------------------
        # Span 3 — agent_contextualization
        # ------------------------------------------------------------------
        contextualization_agent = ContextualizationAgent(
            model_name=model,
            temperature=0.0,
        )
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
        semantic_map: str = contextualization_agent.analyze(
            original_text=original_text,
            amendment_text=amendment_text,
        )
        latency_ms_3 = round((time.time() - t0) * 1000, 2)
        span_ctx.end(
            output={
                "semantic_map_length": len(semantic_map),
                "semantic_map_preview": semantic_map[:400],
            },
            metadata={
                "latency_ms": latency_ms_3,
                "model": model,
                "agent": "ContextualizationAgent",
            },
        )

        # ------------------------------------------------------------------
        # Span 4 — agent_extraction
        # ------------------------------------------------------------------
        extraction_agent = ExtractionAgent(
            model_name=model,
            temperature=0.0,
        )
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
        raw_result: dict = extraction_agent.extract(
            original_text=original_text,
            amendment_text=amendment_text,
            semantic_map=semantic_map,
        )
        latency_ms_4 = round((time.time() - t0) * 1000, 2)
        span_ext.end(
            output={
                "result_keys": list(raw_result.keys()),
                "modified_clauses_count": len(raw_result.get("modified_clauses", [])),
                "result_preview": json.dumps(raw_result)[:400],
            },
            metadata={
                "latency_ms": latency_ms_4,
                "model": model,
                "agent": "ExtractionAgent",
            },
        )

        # ------------------------------------------------------------------
        # Span 5 — validation
        # ------------------------------------------------------------------
        span_val = trace.span(
            name="validation",
            input={"raw_result": raw_result},
        )
        t0 = time.time()
        validated_output = ContractChangeOutput.model_validate(raw_result)
        latency_ms_5 = round((time.time() - t0) * 1000, 2)
        span_val.end(
            output={
                "total_changes": len(validated_output.modified_clauses),
                "summary_preview": validated_output.summary_of_changes[:200],
            },
            metadata={
                "latency_ms": latency_ms_5,
                "schema": "ContractChangeOutput",
                "validation": "pydantic_v2",
            },
        )

        # ------------------------------------------------------------------
        # Build FullAnalysisResult with traceability metadata
        # ------------------------------------------------------------------
        processing_date = datetime.now(tz=timezone.utc).isoformat()
        metadata = ContractMetadata(
            original_file=original_path,
            amendment_file=amendment_path,
            processing_date=processing_date,
            total_changes=len(validated_output.modified_clauses),
            model_used=model,
        )
        full_result = FullAnalysisResult(
            metadata=metadata,
            analysis=validated_output,
        )

        # Update the parent trace with the complete output
        trace.update(
            output={
                "total_changes": len(validated_output.modified_clauses),
                "processing_date": processing_date,
                "model_used": model,
                "summary": validated_output.summary_of_changes,
                "latency_breakdown_ms": {
                    "image_parsing_original": latency_ms_1,
                    "image_parsing_amendment": latency_ms_2,
                    "agent_contextualization": latency_ms_3,
                    "agent_extraction": latency_ms_4,
                    "validation": latency_ms_5,
                    "total": round(latency_ms_1 + latency_ms_2 + latency_ms_3 + latency_ms_4 + latency_ms_5, 2),
                },
            }
        )

        return full_result

    finally:
        # Ensure all buffered events are sent to Langfuse before exiting
        langfuse.flush()


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------


def main() -> None:
    """Parse CLI arguments and invoke the contract analysis pipeline."""
    parser = argparse.ArgumentParser(
        prog="legalmove",
        description=(
            "LegalMove Contract Analyzer — Analiza cambios entre un contrato "
            "original y su adenda usando IA con trazabilidad Langfuse."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Ejemplos:\n"
            "  python -m src.main contrato.png adenda.png\n"
            "  python -m src.main contrato.png adenda.png --model gpt-4o --output resultado.json\n"
        ),
    )
    parser.add_argument(
        "original_image",
        help="Path a la imagen del contrato original (PNG, JPG, JPEG, WEBP, GIF).",
    )
    parser.add_argument(
        "amendment_image",
        help="Path a la imagen de la adenda o enmienda contractual.",
    )
    parser.add_argument(
        "--model",
        default="gpt-4o",
        help='Modelo OpenAI a utilizar (default: "gpt-4o").',
    )
    parser.add_argument(
        "--output",
        default=None,
        metavar="FILE",
        help="Path del archivo donde guardar el resultado JSON. Si se omite, imprime en stdout.",
    )

    args = parser.parse_args()

    try:
        result = run_pipeline(
            original_path=args.original_image,
            amendment_path=args.amendment_image,
            model=args.model,
        )
    except FileNotFoundError as exc:
        print(f"[ERROR] Archivo no encontrado: {exc}", file=sys.stderr)
        sys.exit(1)
    except ValueError as exc:
        print(f"[ERROR] Valor inválido: {exc}", file=sys.stderr)
        sys.exit(1)
    except pydantic.ValidationError as exc:
        print("[ERROR] Fallo de validación del schema de salida:", file=sys.stderr)
        print(exc.json(indent=2), file=sys.stderr)
        sys.exit(2)
    except Exception as exc:  # noqa: BLE001
        print(f"[ERROR] Error inesperado durante la ejecución del pipeline: {exc}", file=sys.stderr)
        sys.exit(3)

    output_json = result.model_dump_json(indent=2)

    if args.output:
        try:
            with open(args.output, "w", encoding="utf-8") as fh:
                fh.write(output_json)
            print(f"[OK] Resultado guardado en: {args.output}", file=sys.stderr)
        except OSError as exc:
            print(f"[ERROR] No se pudo escribir el archivo de salida {args.output!r}: {exc}", file=sys.stderr)
            sys.exit(1)
    else:
        print(output_json)


if __name__ == "__main__":
    main()
