# Entregables del proyecto y requisitos de entrega

### **📦 Entregables**

El proyecto se entrega mediante un **repositorio público de GitHub** que contiene:

| **Entregable** | **Archivo** | **Descripción** |
| --- | --- | --- |
| Script principal | `src/main.py` | Entry point que acepta dos paths de imágenes como argumentos y ejecuta el pipeline completo |
| Agente 1 | `src/agents/contextualization_agent.py` | Agente de contextualización con system prompt y lógica propios |
| Agente 2 | `src/agents/extraction_agent.py` | Agente de extracción con system prompt y lógica propios |
| Utilidades de imagen | `src/image_parser.py` | Funciones de validación, encoding y llamadas multimodales |
| Modelos Pydantic | `src/models.py` | Modelo ContractChangeOutput con los tres campos requeridos |
| Imágenes de prueba | `data/test_contracts/` | Mínimo 2 pares de contratos (4 imágenes) con README explicativo |
| README | `README.md` | Documentación completa con diagramas, arquitectura, setup, uso y decisiones técnicas |
| Dependencias | `requirements.txt` + `.env.example` | Dependencias con versiones fijadas y template de variables de entorno |
| Integración Langfuse | Instrumentación del pipeline principal con una traza que agrupe las etapas del análisis. | Traces con jerarquía de spans para cada etapa del pipeline |