# Rúbrica de evaluación

La evaluación de este proyecto se centra en su capacidad para orquestar **modelos fundacionales multimodales (Visión)** y flujos de trabajo con **agentes especializados**. Se calificará con rigor la precisión en la extracción de texto de documentos originales y sus adendas, así como la efectividad de la colaboración entre agentes para identificar y resumir cambios legales. La rúbrica validará que el sistema no solo funcione, sino que produzca un **JSON estructurado y estrictamente validado**, garantizando que la salida posea la trazabilidad necesaria para un entorno de producción real.

A diferencia de módulos anteriores donde la revisión era asíncrona, esta vez la **evaluación será en vivo y bajo la modalidad 1 a 1**. Durante esta sesión de defensa individual, un corrector validará en tiempo real el funcionamiento de su solución y la lógica detrás de cada agente implementado. Deberán demostrar un dominio técnico total para justificar la elección de sus modelos y la robustez de su sistema ante casos de prueba. El éxito en esta dinámica depende de la coherencia técnica de su arquitectura y de su agilidad para explicar paso a paso cómo garantizan la integridad de los datos extraídos.

### **¿Qué funciones específicas vamos a evaluar?**

Durante la sesión, el evaluador pondrá especial atención en los siguientes componentes de su arquitectura:

- **Capacidad de Visión:** Calidad y fidelidad del texto extraído de las imágenes/PDFs de contratos y adendas.
- **Orquestación de Agentes:** Lógica de colaboración y especialización de los dos agentes en el flujo de trabajo.
- **Validación de Salida:** Integridad y estructura del esquema **JSON** generado (debe ser estrictamente funcional para producción).
- **Trazabilidad y Logs:** Evidencia clara de cada paso del proceso, permitiendo auditar cómo se llegó al resumen final.

**Por favor, revisa a continuación la rúbrica detallada para conocer cada indicador y asegurar que su proyecto cumple con el nivel de excelencia requerido.**

| **Criterio** | **Excelente (100%)** | **Satisfactorio (75%)** | **Insatisfactorio (0-50%)** | **Puntaje** |
| --- | --- | --- | --- | --- |
| **1. FUNCIONALIDAD & REQUISITOS CORE** |  |  |  |  |
| 1.1 Parsing Multimodal | Implementa parse_contract_image() con GPT-4o Vision y base64. Extrae texto con precisión respetando jerarquías (cláusulas/secciones). | El parsing funciona pero pierde parte de la jerarquía o formato del documento original. | No usa visión (solo OCR tradicional). El parsing obtenido tiene mucho ruido y el texto obtenido no es preciso. | 15 |
| 1.2 Arquitectura de 2 Agentes | Separación clara entre ContextualizationAgent y ExtractionAgent. Existe un flujo de handoff lógico donde el segundo usa el mapa del primero. | Ambos agentes existen pero sus responsabilidades se solapan o el traspaso de información es redundante/ineficiente. | Solo hay un agente "monolítico" o los agentes no colaboran (corren de forma independiente sin compartir contexto). | 15 |
| 1.3 Validación Pydantic | El output final cumple estrictamente el modelo ContractChangeOutput y se valida utilizando Pydantic (mediante model_validate() o structured outputs con response_format). Maneja excepciones de validación con elegancia y mensajes claros. | Define el modelo Pydantic pero el flujo no siempre garantiza la validación o faltan descripciones de campo/tipado. | No utiliza Pydantic para validar la salida final o el modelo no incluye los 3 campos obligatorios solicitados. | 10 |
| **2. IMPLEMENTACIÓN TÉCNICA Y PROMPTING** |  |  |  |  |
| 2.1 Calidad del Prompting | System prompts altamente especializados para cada agente (Analista Senior vs Auditor). | Prompts funcionales pero genéricos. No se aprovecha el rol del sistema para mejorar la precisión del análisis legal. | Prompts muy pobres o instrucciones ambiguas que generan alucinaciones frecuentes en la extracción de cambios. | 15 |
| 2.2 Gestión de API y Errores | Manejo robusto de errores de API (timeouts, límites de tokens) y de codificación de imágenes. Uso correcto de variables de entorno. | Implementa manejo de errores básico (try/except genérico). Algunas claves o configuraciones están hardcodeadas. | El código se rompe ante errores de API o falta el archivo .env.example. No hay validación de entrada de archivos. | 10 |
| **3. OBSERVABILIDAD (LANGFUSE)** |  |  |  |  |
| 3.1 Trazabilidad del Workflow | Traza padre con jerarquía clara de spans. Registra inputs, outputs y métricas relevantes (latencia, tokens u otra metadata disponible) para cada etapa del pipeline. | Registra la ejecución en Langfuse pero de forma plana (sin jerarquía de spans) o faltan métricas críticas de tokens/costo. | No hay integración con Langfuse o las trazas están incompletas (solo registra el paso final, por ejemplo). | 15 |
| **4. CALIDAD DE CÓDIGO Y DOCUMENTACIÓN** |  |  |  |  |
| 4.1 Estructura y README | Código modular (POO o funcional limpio). README excelente con diagrama de arquitectura, instrucciones de setup y justificación técnica. | Código funcional pero desorganizado (archivos muy largos). README básico con instrucciones mínimas de instalación. | Repositorio desordenado. Sin README o sin instrucciones claras para que el corrector pueda ejecutar el proyecto. | 10 |
| **5. DEFENSA TÉCNICA EN VIVO** |  |  |  |  |
| 5.1 Presentación y Demo | Explica con fluidez decisiones de diseño. Muestra el dashboard de Langfuse y justifica el uso de agentes. Demo exitosa con 2 casos. | Realiza la demo pero le cuesta explicar la lógica detrás de los agentes o no sabe interpretar las métricas en Langfuse. | No puede ejecutar la demo en vivo o no comprende el flujo de datos entre los componentes de su propio sistema. | 10 |
|  |  |  |  |  |
|  |  |  | **PUNTAJE TOTAL** | 100 |