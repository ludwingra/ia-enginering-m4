#!/usr/bin/env python3
"""
generate_test_contracts.py
Genera 4 imágenes PNG de contratos de prueba para el pipeline LegalMove.

Con Pillow instalado: genera PNGs reales con texto legal en español (800x1100 px).
Sin Pillow: genera PNGs placeholder de 1x1 pixel blanco e instruye al usuario.

Uso:
    python scripts/generate_test_contracts.py
"""

import os
import struct
import zlib

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "test_contracts")

# ---------------------------------------------------------------------------
# Contenido textual de los 4 documentos
# ---------------------------------------------------------------------------

PAR1_ORIGINAL_LINES = [
    "CONTRATO DE SERVICIOS DE CONSULTORÍA EN TECNOLOGÍA DE LA INFORMACIÓN",
    "",
    "Celebrado entre:",
    "  CONTRATANTE: TechCorp S.A., cédula jurídica 3-101-000001",
    "  CONSULTOR:   Juan Pérez Rodríguez, cédula 1-1234-5678",
    "",
    "CLÁUSULA 1 — OBJETO DEL CONTRATO",
    "El CONSULTOR se compromete a prestar servicios especializados de consultoría",
    "en tecnología de la información, incluyendo análisis de sistemas, diseño de",
    "arquitectura de software y asesoría en transformación digital.",
    "",
    "CLÁUSULA 2 — DURACIÓN",
    "El presente contrato tendrá una vigencia de doce (12) meses, con inicio",
    "el 01 de enero de 2025 y vencimiento el 31 de diciembre de 2025.",
    "",
    "CLÁUSULA 3 — HONORARIOS",
    "El CONTRATANTE pagará al CONSULTOR la suma de CINCO MIL DÓLARES",
    "ESTADOUNIDENSES ($5,000.00 USD) mensuales por los servicios prestados.",
    "",
    "CLÁUSULA 4 — FORMA DE PAGO",
    "Los honorarios serán cancelados mediante transferencia bancaria dentro de",
    "los primeros cinco (5) días hábiles de cada mes calendario.",
    "",
    "CLÁUSULA 5 — CONFIDENCIALIDAD",
    "El CONSULTOR se obliga a mantener absoluta reserva sobre toda la información",
    "a la que tenga acceso durante la ejecución del presente contrato, ya sea de",
    "carácter técnico, financiero, comercial o de cualquier otra índole.",
    "",
    "CLÁUSULA 6 — TERMINACIÓN ANTICIPADA",
    "Cualquiera de las partes podrá dar por terminado el presente contrato",
    "mediante aviso escrito con un mínimo de treinta (30) días de preaviso.",
    "",
    "Firmado en San José, Costa Rica, el 01 de enero de 2025.",
    "",
    "________________________          ________________________",
    "TechCorp S.A.                     Juan Pérez Rodríguez",
    "CONTRATANTE                       CONSULTOR",
]

PAR1_ADENDA_LINES = [
    "ADENDA AL CONTRATO DE SERVICIOS DE CONSULTORÍA EN TECNOLOGÍA",
    "",
    "Adenda N.° 1 — Modificación de cláusulas 2 y 3",
    "",
    "Las partes suscritas acuerdan modificar el contrato original suscrito",
    "el 01 de enero de 2025 en los siguientes términos:",
    "",
    "CLÁUSULA 2 — DURACIÓN (MODIFICADA)",
    "Se modifica la fecha de vencimiento del contrato. La nueva fecha de",
    "término es el 30 de junio de 2026. Todo lo demás permanece sin cambios.",
    "",
    "  Texto anterior: '...vencimiento el 31 de diciembre de 2025.'",
    "  Texto nuevo:    '...vencimiento el 30 de junio de 2026.'",
    "",
    "CLÁUSULA 3 — HONORARIOS (MODIFICADA)",
    "Se incrementan los honorarios mensuales del CONSULTOR. A partir del",
    "01 de enero de 2026, el monto mensual será de SIETE MIL QUINIENTOS",
    "DÓLARES ESTADOUNIDENSES ($7,500.00 USD) mensuales.",
    "",
    "  Texto anterior: '...$5,000.00 USD mensuales...'",
    "  Texto nuevo:    '...$7,500.00 USD mensuales...'",
    "",
    "Las restantes cláusulas del contrato original (1, 4, 5 y 6) permanecen",
    "vigentes y sin modificación alguna.",
    "",
    "Firmado en San José, Costa Rica, el 15 de diciembre de 2025.",
    "",
    "________________________          ________________________",
    "TechCorp S.A.                     Juan Pérez Rodríguez",
    "CONTRATANTE                       CONSULTOR",
]

PAR2_ORIGINAL_LINES = [
    "ACUERDO DE CONFIDENCIALIDAD (NON-DISCLOSURE AGREEMENT — NDA)",
    "",
    "Celebrado entre:",
    "  DIVULGANTE: InnovaLab S.A., cédula jurídica 3-101-000099",
    "  RECEPTOR:   María González Vargas, cédula 1-9876-5432",
    "",
    "CLÁUSULA 1 — DEFINICIÓN DE INFORMACIÓN CONFIDENCIAL",
    "Se considera información confidencial toda aquella que sea designada como",
    "tal por el DIVULGANTE, incluyendo pero no limitado a: procesos, fórmulas,",
    "metodologías, datos de clientes, estrategias comerciales y código fuente.",
    "",
    "CLÁUSULA 2 — OBLIGACIONES DEL RECEPTOR",
    "El RECEPTOR se obliga a: (a) mantener en estricta confidencialidad toda",
    "la información recibida; (b) no reproducir ni distribuir dicha información",
    "sin autorización escrita previa del DIVULGANTE; (c) notificar de inmediato",
    "cualquier divulgación accidental o no autorizada.",
    "",
    "CLÁUSULA 3 — ALCANCE TERRITORIAL",
    "Las obligaciones del presente acuerdo serán aplicables exclusivamente",
    "dentro del territorio de la República de Costa Rica.",
    "",
    "CLÁUSULA 4 — RESTRICCIÓN DE USO EN REDES SOCIALES",
    "El RECEPTOR queda expresamente prohibido de divulgar, referenciar o",
    "comentar cualquier aspecto de la información confidencial a través de",
    "redes sociales, plataformas digitales o medios de comunicación masiva.",
    "",
    "CLÁUSULA 5 — VIGENCIA",
    "El presente acuerdo tendrá una vigencia de dos (2) años contados a",
    "partir de la fecha de firma, renovable por períodos iguales.",
    "",
    "CLÁUSULA 6 — PENALIDADES POR INCUMPLIMIENTO",
    "El incumplimiento de cualquiera de las obligaciones pactadas dará",
    "derecho al DIVULGANTE a reclamar daños y perjuicios, así como a",
    "solicitar medidas cautelares ante la autoridad judicial competente.",
    "",
    "Firmado en San José, Costa Rica, el 15 de marzo de 2025.",
    "",
    "________________________          ________________________",
    "InnovaLab S.A.                    María González Vargas",
    "DIVULGANTE                        RECEPTOR",
]

PAR2_ADENDA_LINES = [
    "ADENDA AL ACUERDO DE CONFIDENCIALIDAD (NDA)",
    "",
    "Adenda N.° 1 — Modificación de alcance territorial, eliminación de",
    "cláusula 4 e incorporación de cláusula de arbitraje internacional",
    "",
    "Las partes suscritas acuerdan modificar el NDA original suscrito",
    "el 15 de marzo de 2025 en los siguientes términos:",
    "",
    "CLÁUSULA 3 — ALCANCE TERRITORIAL (MODIFICADA)",
    "Se amplía el ámbito territorial de aplicación del acuerdo.",
    "",
    "  Texto anterior: '...exclusivamente dentro del territorio de la",
    "                   República de Costa Rica.'",
    "  Texto nuevo:    '...en todos los países de América Latina y el",
    "                   Caribe (LATAM), incluyendo pero no limitado a:",
    "                   México, Colombia, Argentina, Chile, Perú y Brasil.'",
    "",
    "CLÁUSULA 4 — RESTRICCIÓN DE USO EN REDES SOCIALES (ELIMINADA)",
    "La Cláusula 4 del contrato original queda sin efecto y se elimina",
    "en su totalidad. Las demás cláusulas se renumeran en consecuencia.",
    "",
    "CLÁUSULA 7 — ARBITRAJE INTERNACIONAL (NUEVA)",
    "Cualquier controversia que surja en conexión con el presente acuerdo",
    "será resuelta definitivamente mediante arbitraje internacional bajo",
    "el Reglamento de Arbitraje de la Cámara de Comercio Internacional",
    "(ICC), con sede en la ciudad de Miami, Florida, Estados Unidos de",
    "América. El idioma del arbitraje será el español. El laudo arbitral",
    "será definitivo y vinculante para ambas partes.",
    "",
    "Las restantes cláusulas (1, 2, 5 y 6) permanecen sin modificación.",
    "",
    "Firmado en San José, Costa Rica, el 20 de agosto de 2025.",
    "",
    "________________________          ________________________",
    "InnovaLab S.A.                    María González Vargas",
    "DIVULGANTE                        RECEPTOR",
]

CONTRACTS = [
    ("par1_contrato_original.png", PAR1_ORIGINAL_LINES),
    ("par1_adenda.png", PAR1_ADENDA_LINES),
    ("par2_contrato_original.png", PAR2_ORIGINAL_LINES),
    ("par2_adenda.png", PAR2_ADENDA_LINES),
]

# ---------------------------------------------------------------------------
# Generación SIN Pillow — PNG 1×1 pixel blanco válido (bytes hardcoded)
# ---------------------------------------------------------------------------

def _make_png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    """Construye un chunk PNG con CRC correcto."""
    crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)


def generate_placeholder_png(path: str) -> None:
    """Genera un PNG 1×1 pixel blanco mínimo válido."""
    png_signature = b"\x89PNG\r\n\x1a\n"

    # IHDR: width=1, height=1, bit_depth=8, color_type=2 (RGB), compress=0, filter=0, interlace=0
    ihdr_data = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
    ihdr = _make_png_chunk(b"IHDR", ihdr_data)

    # IDAT: un pixel RGB blanco (filter byte 0 + R G B)
    raw_row = b"\x00\xFF\xFF\xFF"
    compressed = zlib.compress(raw_row)
    idat = _make_png_chunk(b"IDAT", compressed)

    iend = _make_png_chunk(b"IEND", b"")

    with open(path, "wb") as f:
        f.write(png_signature + ihdr + idat + iend)


# ---------------------------------------------------------------------------
# Generación CON Pillow — PNG 800×1100 con texto
# ---------------------------------------------------------------------------

def generate_png_with_pillow(path: str, lines: list[str]) -> None:
    from PIL import Image, ImageDraw, ImageFont

    WIDTH, HEIGHT = 800, 1100
    MARGIN_X = 50
    MARGIN_Y = 60
    LINE_HEIGHT = 22
    FONT_SIZE_TITLE = 14
    FONT_SIZE_BODY = 12

    img = Image.new("RGB", (WIDTH, HEIGHT), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)

    # Intentar fuente del sistema; caer a default si no disponible
    try:
        font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", FONT_SIZE_TITLE)
        font_body = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", FONT_SIZE_BODY)
    except (IOError, OSError):
        try:
            font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", FONT_SIZE_TITLE)
            font_body = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", FONT_SIZE_BODY)
        except (IOError, OSError):
            font_title = ImageFont.load_default()
            font_body = ImageFont.load_default()

    y = MARGIN_Y
    for i, line in enumerate(lines):
        if y + LINE_HEIGHT > HEIGHT - MARGIN_Y:
            break  # no desbordar la imagen

        # Primera línea en negrita/título
        font = font_title if i == 0 else font_body
        color = (0, 0, 0)

        # Resaltar encabezados de cláusula
        if line.startswith("CLÁUSULA") or line.startswith("Adenda N.°"):
            font = font_title
            color = (20, 20, 100)

        draw.text((MARGIN_X, y), line, font=font, fill=color)
        y += LINE_HEIGHT

    img.save(path, "PNG")


# ---------------------------------------------------------------------------
# Punto de entrada
# ---------------------------------------------------------------------------

def main() -> None:
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Detectar Pillow
    try:
        import PIL  # noqa: F401
        has_pillow = True
    except ImportError:
        has_pillow = False

    if has_pillow:
        print("Pillow detectado — generando PNGs con contenido textual real.")
        for filename, lines in CONTRACTS:
            out_path = os.path.join(OUTPUT_DIR, filename)
            generate_png_with_pillow(out_path, lines)
            print(f"  [OK] {out_path}")
        print("\nListo. 4 contratos generados en data/test_contracts/")
    else:
        print("Pillow NO está instalado — generando PNGs placeholder (1×1 px).")
        for filename, _ in CONTRACTS:
            out_path = os.path.join(OUTPUT_DIR, filename)
            generate_placeholder_png(out_path)
            print(f"  [PLACEHOLDER] {out_path}")
        print(
            "\nPara generar los PNGs reales con texto, instala Pillow y vuelve a ejecutar:\n"
            "    pip install Pillow\n"
            "    python scripts/generate_test_contracts.py\n"
            "\nAlternativamente, descarga las imágenes reales desde:\n"
            "    https://drive.google.com/drive/folders/1JGZmR0UiJLvs1yxoh6VhWUnfm8FaidSw"
        )


if __name__ == "__main__":
    main()
