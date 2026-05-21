from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class ClauseChange(BaseModel):
    """Representa un cambio individual detectado en una cláusula del contrato."""

    clause_id: str = Field(
        description="Identificador único de la cláusula (ej: '3.1', '5.2.a')"
    )
    clause_title: str = Field(
        description="Título o nombre descriptivo de la cláusula"
    )
    original_text: str = Field(
        description="Texto original de la cláusula en el contrato base"
    )
    amended_text: str = Field(
        description="Texto modificado de la cláusula en la adenda; vacío si fue eliminada"
    )
    change_type: Literal["added", "modified", "removed"] = Field(
        description="Tipo de cambio aplicado a la cláusula: 'added' (nueva), 'modified' (modificada), 'removed' (eliminada)"
    )
    significance: Literal["high", "medium", "low"] = Field(
        description="Nivel de importancia del cambio para el contrato: 'high' (alto), 'medium' (medio), 'low' (bajo)"
    )


class ContractChangeOutput(BaseModel):
    """Modelo principal de salida del análisis de cambios contractuales. Contiene los 3 campos obligatorios del resultado."""

    model_config = ConfigDict(strict=True)

    summary_of_changes: str = Field(
        description="Resumen ejecutivo de todos los cambios detectados entre el contrato original y la adenda"
    )
    modified_clauses: list[ClauseChange] = Field(
        description="Lista estructurada de cada cambio detectado, con detalle por cláusula"
    )
    risk_assessment: str = Field(
        description="Evaluación del impacto legal y los riesgos derivados de los cambios identificados"
    )

    @classmethod
    def example(cls) -> ContractChangeOutput:
        """Retorna una instancia válida de ejemplo, útil para tests y demos."""
        return cls(
            summary_of_changes=(
                "Se detectaron 2 cambios en el contrato: modificación de la cláusula de "
                "penalidades (3.1) y eliminación de la cláusula de exclusividad (5.2.a)."
            ),
            modified_clauses=[
                ClauseChange(
                    clause_id="3.1",
                    clause_title="Penalidades por incumplimiento",
                    original_text="La penalidad por incumplimiento será del 5% mensual.",
                    amended_text="La penalidad por incumplimiento será del 10% mensual.",
                    change_type="modified",
                    significance="high",
                ),
                ClauseChange(
                    clause_id="5.2.a",
                    clause_title="Cláusula de exclusividad",
                    original_text="El proveedor se obliga a no prestar servicios similares a terceros durante la vigencia del contrato.",
                    amended_text="",
                    change_type="removed",
                    significance="medium",
                ),
            ],
            risk_assessment=(
                "El aumento de la penalidad al 10% representa un riesgo financiero significativo ante "
                "cualquier retraso. La eliminación de la cláusula de exclusividad libera al proveedor "
                "para trabajar con competidores, lo que puede afectar la confidencialidad y calidad del servicio."
            ),
        )


class ContractMetadata(BaseModel):
    """Metadatos del procesamiento para trazabilidad del análisis contractual."""

    original_file: str = Field(
        description="Path del archivo del contrato original"
    )
    amendment_file: str = Field(
        description="Path del archivo de la adenda o enmienda"
    )
    processing_date: str = Field(
        description="Fecha y hora de procesamiento del análisis (formato ISO 8601)"
    )
    total_changes: int = Field(
        description="Número total de cambios detectados en el análisis"
    )
    model_used: str = Field(
        default="gpt-4o",
        description="Nombre del modelo de IA utilizado para el análisis",
    )


class FullAnalysisResult(BaseModel):
    """Resultado completo del análisis que combina metadatos de trazabilidad con el output del análisis."""

    metadata: ContractMetadata = Field(
        description="Metadatos del procesamiento: archivos analizados, fecha y modelo usado"
    )
    analysis: ContractChangeOutput = Field(
        description="Resultado estructurado del análisis de cambios contractuales"
    )
