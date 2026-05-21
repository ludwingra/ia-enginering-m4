# Contratos de Prueba — LegalMove

## Descripción

Este directorio contiene los pares de contratos de prueba para validar el pipeline de análisis contractual.

## Pares de contratos

### Par 1 — Cambios simples
- **`par1_contrato_original.png`** — Contrato de servicios de consultoría IT
- **`par1_adenda.png`** — Adenda que modifica el monto mensual (de $5,000 a $7,500) y la fecha de vencimiento (de 31/12/2025 a 30/06/2026)
- **Cambios esperados:** 2 cláusulas modificadas (monto + fecha)

### Par 2 — Cambios complejos
- **`par2_contrato_original.png`** — Contrato de confidencialidad (NDA)
- **`par2_adenda.png`** — Adenda que agrega cláusula de arbitraje internacional, modifica el alcance territorial (de nacional a LATAM), y elimina la restricción de uso de datos en redes sociales
- **Cambios esperados:** 1 cláusula agregada, 1 modificada, 1 eliminada

## Cómo obtener las imágenes

### Opción A — Recursos proporcionados
Descargar desde el Google Drive del curso: [Recursos adicionales](https://drive.google.com/drive/folders/1JGZmR0UiJLvs1yxoh6VhWUnfm8FaidSw)

### Opción B — Generar propios
1. Crear documentos en Google Docs / Word con el contenido descrito arriba
2. Exportar como PDF → Convertir a PNG
3. Nombrar los archivos siguiendo la convención: `par{N}_{tipo}.png`

## Ejecución
```bash
# Par 1 (simple)
python -m src.main data/test_contracts/par1_contrato_original.png data/test_contracts/par1_adenda.png

# Par 2 (complejo)
python -m src.main data/test_contracts/par2_contrato_original.png data/test_contracts/par2_adenda.png
```
