"""
main.py — LegalMove Contract Analyzer — CLI Entry Point

Orquesta el pipeline completo de análisis contractual con instrumentación
Langfuse para trazabilidad jerárquica de spans:

    Trace padre: "contract_analysis"
      ├── Span: "image_parsing_original"
      ├── Span: "image_parsing_amendment"
      ├── Span: "agent_contextualization"  (creado internamente por pipeline.py)
      ├── Span: "agent_extraction"         (creado internamente por pipeline.py)
      └── Span: "validation"               (creado internamente por pipeline.py)

Uso:
    python -m src.main original.png amendment.png [--model gpt-4o] [--output result.json]
"""

import argparse
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import pydantic
from dotenv import load_dotenv
from langfuse import Langfuse

from src.image_parser import parse_contract_image
from src.agents.pipeline import ContractAnalysisPipeline
from src.models import ContractMetadata, FullAnalysisResult


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
    inputs, outputs, and latency_ms for each pipeline stage. Image parsing spans
    are managed here; agent orchestration spans are delegated to
    ContractAnalysisPipeline.run() via the ``trace`` parameter.

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

    # Pre-validate image paths before initialising any external clients so that
    # missing-file errors surface with exit code 1 even when API keys are absent.
    for label, img_path in (("original", original_path), ("amendment", amendment_path)):
        p = Path(img_path)
        if not p.exists():
            raise FileNotFoundError(f"Image file not found ({label}): {img_path!r}")
        if not p.is_file():
            raise FileNotFoundError(f"Path is not a regular file ({label}): {img_path!r}")

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
        original_text = parse_contract_image(original_path, model=model)
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
        amendment_text = parse_contract_image(amendment_path, model=model)
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
        # Spans 3–5 — agent_contextualization, agent_extraction, validation
        # Delegated to ContractAnalysisPipeline.run() which creates its own
        # child spans when a trace is provided.
        # ------------------------------------------------------------------
        pipeline = ContractAnalysisPipeline(
            model_name=model,
            temperature=0.0,
        )
        validated_output = pipeline.run(
            original_text=original_text,
            amendment_text=amendment_text,
            trace=trace,
        )

        # Aggregate latency from pipeline spans (spans 3–5 are created inside pipeline)
        latency_ms_1_2 = latency_ms_1 + latency_ms_2

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
                "latency_image_parsing_ms": round(latency_ms_1_2, 2),
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
