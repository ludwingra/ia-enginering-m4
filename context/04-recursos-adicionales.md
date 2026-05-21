# **Recursos adicionales**

### **Contratos de prueba simulados**

Para los pares de contratos de prueba podés:

- Utilizar los archivos ya generados: [Recursos adicionales](https://drive.google.com/drive/folders/1JGZmR0UiJLvs1yxoh6VhWUnfm8FaidSw)
- O generar tus propios documentos PDF simples con herramientas como Canva, Google Docs o Word, exportarlos como imágenes. Podes evaluar los siguientes escenarios:

**→ Par 1** (cambios simples): Contrato de servicios donde la enmienda modifica únicamente el monto mensual y la fecha de vencimiento.

**→ Par 2** (cambios complejos): Contrato de confidencialidad donde la enmienda agrega una cláusula nueva, modifica el alcance territorial y elimina una restricción de uso.

### **OpenAI Vision: Análisis de imágenes**

- Documentación oficial: [Images and vision | OpenAI API](https://developers.openai.com/api/docs/guides/images-vision?format=base64-encoded#analyze-images)

**Setup de Langfuse**

- Crear cuenta en cloud.langfuse.com.
- Crear un nuevo proyecto y obtener `LANGFUSE_PUBLIC_KEY y LANGFUSE_SECRET_KEY.`
- Instalar con `pip install langfuse.`
- Inicializar el cliente con las keys desde variables de entorno.

Variables de entorno requeridas (.env.example)

- `OPENAI_API_KEY=your-key-here`
- `LANGFUSE_PUBLIC_KEY=pk-lf-xxx`
- `LANGFUSE_SECRET_KEY=sk-lf-xxx`
- `LANGFUSE_HOST=https://cloud.langfuse.com`