"""
image_parser.py — LegalMove Contract Image Parser
Parses legal contract images using GPT-4o Vision API.
"""

import base64
import logging
import os
import time
from pathlib import Path

import openai

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Supported image extensions and their MIME types
# ---------------------------------------------------------------------------
_SUPPORTED_EXTENSIONS: dict[str, str] = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".webp": "image/webp",
    ".gif": "image/gif",
}

# ---------------------------------------------------------------------------
# Lazy-initialized OpenAI client
# ---------------------------------------------------------------------------
_client: openai.OpenAI | None = None


def _get_client() -> openai.OpenAI:
    """Return the module-level OpenAI client, initialising it on first call."""
    global _client
    if _client is None:
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            raise EnvironmentError(
                "OPENAI_API_KEY is not set. "
                "Add it to your .env file or export it as an environment variable."
            )
        _client = openai.OpenAI(api_key=api_key)
    return _client


# ---------------------------------------------------------------------------
# System prompt for legal document extraction
# ---------------------------------------------------------------------------
_LEGAL_EXTRACTION_PROMPT = """\
Eres un experto en análisis de documentos legales. Tu tarea es extraer el texto \
completo del documento de la imagen proporcionada.

INSTRUCCIONES CRÍTICAS:
- Preserva TODA la jerarquía del documento: títulos, secciones, cláusulas, sub-cláusulas
- Formatea el resultado como Markdown estructurado
- Usa ## para títulos principales, ### para secciones, #### para cláusulas
- Numera las cláusulas exactamente como aparecen en el documento
- NO omitas ni resumas ningún texto — extrae TODO el contenido
- Si hay tablas, represéntalas en formato Markdown
- Si hay firmas o sellos, indícalos como [FIRMA] o [SELLO]
- Identifica y preserva el tipo de documento: contrato, adenda, enmienda, anexo
- Registra las partes involucradas si aparecen en el encabezado
- Presta especial atención a: montos, fechas, plazos, porcentajes y condiciones
- Si hay texto parcialmente legible, indica con [ILEGIBLE] en vez de adivinar
- Preserva la numeración exacta de cada cláusula y sub-cláusula
"""

# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------


def validate_image_path(image_path: str) -> Path:
    """Validate that *image_path* exists and has a supported extension.

    Parameters
    ----------
    image_path:
        Filesystem path to the image file.

    Returns
    -------
    Path
        Resolved :class:`pathlib.Path` object for the image.

    Raises
    ------
    ValueError
        If the file does not exist or the extension is not supported.
    """
    path = Path(image_path).resolve()

    if not path.exists():
        raise ValueError(f"Image file not found: {image_path!r}")

    if not path.is_file():
        raise ValueError(f"Path is not a regular file: {image_path!r}")

    suffix = path.suffix.lower()
    if suffix not in _SUPPORTED_EXTENSIONS:
        supported = ", ".join(_SUPPORTED_EXTENSIONS)
        raise ValueError(
            f"Unsupported image extension {suffix!r} for file {image_path!r}. "
            f"Supported extensions: {supported}"
        )

    return path


def encode_image_to_base64(image_path: str) -> str:
    """Read *image_path* and return its contents as a Base64-encoded string.

    Parameters
    ----------
    image_path:
        Filesystem path to the image file.

    Returns
    -------
    str
        Base64-encoded representation of the image bytes.

    Raises
    ------
    IOError
        If the file cannot be read.
    """
    try:
        with open(image_path, "rb") as fh:
            raw_bytes = fh.read()
    except OSError as exc:
        raise IOError(
            f"Could not read image file {image_path!r}: {exc}"
        ) from exc

    return base64.b64encode(raw_bytes).decode("utf-8")


def get_image_media_type(image_path: str) -> str:
    """Return the MIME media type for *image_path* based on its extension.

    Parameters
    ----------
    image_path:
        Filesystem path (or just the filename) of the image.

    Returns
    -------
    str
        MIME type string, e.g. ``"image/png"``.

    Raises
    ------
    ValueError
        If the extension is not in the supported set.
    """
    suffix = Path(image_path).suffix.lower()
    media_type = _SUPPORTED_EXTENSIONS.get(suffix)
    if media_type is None:
        supported = ", ".join(_SUPPORTED_EXTENSIONS)
        raise ValueError(
            f"Cannot determine media type for extension {suffix!r}. "
            f"Supported extensions: {supported}"
        )
    return media_type


# ---------------------------------------------------------------------------
# Main parser
# ---------------------------------------------------------------------------

_MAX_RETRIES = 3
_BACKOFF_SECONDS = [1, 2, 4]  # exponential backoff: 1 s, 2 s, 4 s


def parse_contract_image(image_path: str, model: str = "gpt-4o") -> str:
    """Extract text from a legal-contract image using GPT-4o Vision.

    The extracted text preserves the hierarchical structure of the document
    (titles, sections, clauses, sub-clauses) and is returned as a Markdown
    string.

    Parameters
    ----------
    image_path:
        Filesystem path to the contract image.
    model:
        OpenAI model identifier to use for the Vision API call (default: "gpt-4o").

    Returns
    -------
    str
        Markdown-formatted text extracted from the contract.

    Raises
    ------
    ValueError
        If *image_path* is invalid or the extension is unsupported.
    IOError
        If the image file cannot be read.
    openai.APIError
        If the OpenAI API returns an unrecoverable error after all retries.
    EnvironmentError
        If ``OPENAI_API_KEY`` is not set.
    """
    # 1. Validate and encode the image
    validated_path = validate_image_path(image_path)
    image_b64 = encode_image_to_base64(str(validated_path))
    media_type = get_image_media_type(str(validated_path))

    # 2. Build the Vision API message payload
    messages = [
        {
            "role": "system",
            "content": _LEGAL_EXTRACTION_PROMPT,
        },
        {
            "role": "user",
            "content": [
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:{media_type};base64,{image_b64}",
                        "detail": "high",
                    },
                },
                {
                    "type": "text",
                    "text": (
                        "Por favor, extrae todo el texto del contrato legal "
                        "en esta imagen, respetando su estructura jerárquica."
                    ),
                },
            ],
        },
    ]

    client = _get_client()
    last_error: Exception | None = None

    for attempt in range(1, _MAX_RETRIES + 1):
        try:
            response = client.chat.completions.create(
                model=model,
                messages=messages,  # type: ignore[arg-type]
                max_tokens=8192,
            )
            extracted_text: str = response.choices[0].message.content or ""
            return extracted_text

        except openai.APITimeoutError as exc:
            last_error = exc
            _log_retry(attempt, "APITimeoutError", exc)

        except openai.RateLimitError as exc:
            last_error = exc
            _log_retry(attempt, "RateLimitError", exc)

        except openai.APIError as exc:
            # Non-retryable API errors: log and re-raise immediately
            logger.error("OpenAI APIError (attempt %d): %s", attempt, exc)
            raise openai.APIError(
                f"OpenAI API error while parsing {image_path!r}: {exc}",
                request=exc.request,  # type: ignore[arg-type]
                body=exc.body,
            ) from exc

        # Wait before the next retry (no sleep after the last attempt)
        if attempt < _MAX_RETRIES:
            wait = _BACKOFF_SECONDS[attempt - 1]
            logger.warning(
                "Retrying in %ds... (attempt %d/%d)", wait, attempt, _MAX_RETRIES
            )
            time.sleep(wait)

    # All retries exhausted
    raise openai.APIError(
        f"Failed to parse {image_path!r} after {_MAX_RETRIES} attempts. "
        f"Last error: {last_error}",
        request=getattr(last_error, "request", None),  # type: ignore[arg-type]
        body=getattr(last_error, "body", None),
    ) from last_error


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _log_retry(attempt: int, error_type: str, exc: Exception) -> None:
    """Write a retry warning to the logger."""
    logger.warning("%s on attempt %d/%d: %s", error_type, attempt, _MAX_RETRIES, exc)
