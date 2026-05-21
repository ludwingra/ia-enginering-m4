---
name: fallback
description: "Activa modo resiliencia cuando Claude Code CLI no está disponible (rate limit, outage, tokens agotados)"
---

# /fallback — Resiliencia y Fallback ASD SDK v3.18.0

> **Uso:** Ejecutar `/fallback` cuando Claude Code CLI no esta disponible (rate limit, outage, tokens agotados).
> **Capability:** `bash_execute` — ejecuta `fallback-switch.sh`.
> **Modo degradado:** Si el script no esta disponible, generar contexto manualmente copiando el estado de `claude-progress.json`.

---

## ROL

Sos el agente de resiliencia del ASD SDK. Tu trabajo es activar el modo de fallback para que el usuario pueda continuar trabajando con modelos alternativos gratuitos cuando Claude Code no esta disponible.

---

## PASO 1 — Detectar herramientas disponibles

Ejecutar deteccion de herramientas y API keys:

```bash
bash ~/.asd-sdk/bin/fallback-switch.sh --detect-only
```

Esto imprime un JSON con:
- **tools:** aider, curl, ollama, clipboard disponibles
- **api_keys:** GOOGLE_API_KEY, XAI_API_KEY, MISTRAL_API_KEY, OPENROUTER_API_KEY configuradas

Si no hay API keys configuradas, indicar al usuario que siga la guia en `docs/fallback-models-setup.md`.

---

## PASO 2 — Activar fallback

Ejecutar el flujo completo:

```bash
bash ~/.asd-sdk/bin/fallback-switch.sh
```

El script presenta un menu interactivo de modelos free-tier y el usuario elige cual usar. Luego:

- **Con Aider instalado:** Ofrece lanzar Aider preconfigurado con el modelo elegido y el contexto portatil
- **Sin Aider:** Ofrece 3 opciones manuales:
  1. **Web** — Abre AI Studio / console del proveedor en el navegador y copia contexto al clipboard
  2. **Curl** — Muestra comando curl listo para pegar con la API del modelo elegido
  3. **Clipboard** — Copia el contexto portatil (FALLBACK_CONTEXT.md) al portapapeles

El script genera automaticamente `.claude/memory/FALLBACK_CONTEXT.md` con el estado completo del trabajo en progreso.

---

## PASO 3 — Retornar a Claude Code

Cuando Claude Code vuelve a estar disponible, el usuario ejecuta:

```bash
bash ~/.asd-sdk/bin/fallback-switch.sh --return
```

Esto:
1. Marca `fallback_state.active = false` en `claude-progress.json`
2. Registra `returned_at` con timestamp
3. Muestra resumen de la sesion de fallback
4. Sugiere ejecutar `/init` para sincronizar el estado

Despues, al abrir Claude Code, ejecutar `/init` para que el Initializer Agent detecte los cambios hechos durante el fallback.

---

*ASD SDK v3.18.0 — Resilience Layer*
