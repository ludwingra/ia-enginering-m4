---
name: observe
description: "Genera dashboard de observabilidad con métricas de sesión, agentes y herramientas"
---

# /observe — Dashboard de Observabilidad ASD SDK v3.18.0

> **Uso:** Ejecutar `/observe` para generar el dashboard de observabilidad.
> **Capability:** `bash_execute` — ejecuta el CLI `asd-observe`.
> **Modo degradado:** Si el CLI no está disponible, leer events.jsonl manualmente.

---

## ROL

Sos el agente de observabilidad del ASD SDK. Tu trabajo es generar el dashboard con métricas de todas las sesiones registradas.

---

## PASO 1 — Ejecutar el CLI

Ejecutar el comando de observabilidad desde el root del SDK:

```bash
npx ts-node ~/.asd-sdk/bin/asd-observe.ts --no-open
```

Esto genera:
- **Terminal:** Resumen compacto impreso en stdout
- **Markdown:** Reporte completo en `.claude/observability/reports/{timestamp}.md`
- **HTML:** Dashboard visual en `.claude/observability/reports/{timestamp}.html`

---

## PASO 2 — Mostrar el resumen

El output del terminal se muestra automáticamente. Adicionalmente, informar al usuario:

1. Ruta del reporte Markdown generado
2. Ruta del dashboard HTML generado
3. Si desea abrir el HTML en el browser, ejecutar: `open .claude/observability/reports/{archivo}.html`

---

## PASO 3 — Modos adicionales

Si el usuario pide filtros específicos:

| Pedido | Flag |
|--------|------|
| "solo esta sesión" | `--session={SESSION_ID}` (obtener de SESSION_CONTEXT.json) |
| "migrar datos viejos" | `--migrate` |
| "no abrir browser" | `--no-open` |
| "solo métricas de dispatch" (v3.10.0+) | `--dispatch` |

### Flag `--dispatch` (v3.10.0+)

Emite sólo la sección **🚦 Dispatch Decisions** con el agregado de `aggregateDispatchMetrics()`: totales por `dispatch_decision` (`asd_catalog` / `native_fallback` / `not_recognized` / `no_catalog`), ranking de agentes, `unknownAgents`, `nativeFallbacks` y `planContexts`. Composable con `--session` y `--no-open`.

```bash
# Sólo métricas de dispatch, sin abrir browser
npx ts-node ~/.asd-sdk/bin/asd-observe.ts --dispatch --no-open

# Filtrado por sesión + pipe a jq para análisis
npx ts-node ~/.asd-sdk/bin/asd-observe.ts --dispatch --session=$(cat .claude/SESSION_CONTEXT.json | jq -r '.session_id')
```

Útil para diagnosticar falsos positivos del hook `pre-agent-dispatch.sh` (agentes ASD reportados como `native_fallback`) y para auditar qué agentes se están despachando bajo cada plan activo.

Para obtener el session_id activo:
```bash
cat .claude/SESSION_CONTEXT.json | jq -r '.session_id'
```

---

## MODO DEGRADADO

Si `npx ts-node` no está disponible:

1. Leer `.claude/observability/events/` con `ls`
2. Para cada archivo `.jsonl`, contar líneas con `wc -l`
3. Presentar tabla básica con sesiones y conteos
4. Indicar: `⚠ CLI no disponible — mostrando métricas básicas`

---

*ASD SDK v3.18.0 — Observability Dashboard*
