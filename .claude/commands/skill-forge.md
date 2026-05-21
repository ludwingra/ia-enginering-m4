---
name: skill-forge
description: "Wizard interactivo para crear skills ASD — entrevista de 5 pasos, genera SKILL.md e integra en el ecosistema SDK (manifest, checksums, templates, CHANGELOG)"
---

# Comando /skill-forge — Wizard de Creacion de Skills ASD SDK v3.18.0

> **Uso:** `/skill-forge` o `/skill-forge <nombre-skill>`
> **Skill backend:** `.claude/skills/skill-forge/SKILL.md`
> **Modelo:** Opus 4.6 (forzado por metadata de la skill)

---

## ACTIVACION

Al ejecutar `/skill-forge`, el sistema:

1. **Carga la skill `skill-forge`** desde `.claude/skills/skill-forge/SKILL.md`
2. **Parsea `$ARGUMENTS`** para detectar nombre pre-definido
3. **Inicia el protocolo de entrevista** de 5 pasos

---

## DETECCION DE ARGUMENTOS

| Invocacion                    | Comportamiento                                           |
|-------------------------------|----------------------------------------------------------|
| `/skill-forge`                | Inicia entrevista completa desde Step 1                  |
| `/skill-forge <nombre>`      | Pre-carga nombre, valida formato, salta a Step 1.b       |
| `/skill-forge --help`        | Muestra este resumen de uso y se detiene                 |

Si `$ARGUMENTS` contiene `--help`, mostrar:

```
Skill Forge — Wizard de creacion de skills ASD

  /skill-forge              Inicia entrevista interactiva completa
  /skill-forge <nombre>     Inicia con nombre pre-definido (salta Step 1.a)

  Protocolo de 5 pasos:
    Step 1: Nombre y proposito
    Step 2: Trigger contexts (frases de activacion)
    Step 3: Patron de creacion (skill unica vs A+B orquestada)
    Step 4: Metadata ASD (tier, model, load_strategy, etc.)
    Step 5: Evals (opcional, via skill-creator si disponible)

  Despues de la entrevista genera SKILL.md e integra en el SDK:
    - .claude/skills/<nombre>/SKILL.md
    - templates/skills/<nombre>/SKILL.md
    - skills-manifest.json (entrada nueva)
    - skills-checksums.json (regenerado)
    - CHANGELOG.md (entrada feat)
```

Si `$ARGUMENTS` contiene un nombre (texto sin `--`):
- Validar formato: `[a-z0-9-]{3,50}`
- Si valido: asignar como `skill_name`, iniciar en Step 1.b (descripcion)
- Si invalido: rechazar y pedir correccion antes de continuar

---

## PROTOCOLO DE ENTREVISTA (5 PASOS)

Ejecutar los 5 pasos en orden estricto. NO avanzar al siguiente sin respuesta del usuario.

Referencia completa del protocolo: `.claude/skills/skill-forge/SKILL.md` seccion "Protocolo de Entrevista".

### Step 1 — Nombre y proposito

1. **Nombre** (si no vino en `$ARGUMENTS`): lowercase con guiones, patron `[a-z0-9-]{3,50}`
2. **Descripcion en una linea**: que hace y cuando se activa (formato "Use when...")
3. **Formato de salida esperado**: que genera la skill (archivos, bloques markdown, config)

### Step 2 — Trigger contexts

Preguntar: "Cuando deberia activarse esta skill? Que frases o contextos la disparan?"

- Incluir frases directas e indirectas
- Hacer la descripcion "pushy" (mejor activar de mas que de menos)
- Registrar como keywords para frontmatter `description` y manifest `tags`

### Step 3 — Patron de creacion

Presentar tabla de heuristicas (skill unica vs A+B orquestada):

| Senal                       | Skill unica | A+B orquestada |
|-----------------------------|-------------|----------------|
| Subdominios                 | 1-2         | 3+             |
| Lineas estimadas del SKILL  | <= 400      | > 500          |
| Cross-cutting concerns      | No          | Si             |

**Default: skill unica.** Solo recomendar A+B si el usuario identifica 3+ subdominios con cross-cutting concerns.

### Step 4 — Metadata ASD

Presentar campos con defaults segun tier. Preguntar: "Acepta defaults o quiere personalizar?"

Campos: tier, loop_phase, load_strategy, model, required, agent_allowlist, gates_covered, mutual_exclusion, token_estimate, dependencies.

### Step 5 — Evals (opcional)

Verificar disponibilidad de `skill-creator:skill-creator`. Si disponible, ofrecer loop RED-GREEN-REFACTOR. Si no, generar directamente.

---

## GENERACION

Segun resultado de la entrevista:

- **Con skill-creator:** Invocar `Skill("skill-creator:skill-creator")` con contexto recopilado
- **Directa:** Generar SKILL.md con frontmatter YAML + protocolo + ejemplo

Estructura del SKILL.md generado:
```
---
name: <nombre>
description: "<descripcion pushy>"
model: <model>
metadata:
  author: <author>
  version: "1.0.0"
  loop_phase: "<loop_phase>"
  token_budget: "<max_token_estimate>"
---
# <Nombre> -- <Proposito>
[Contenido: modo de uso, protocolo, ejemplo]
```

---

## INTEGRACION SDK

Despues de generar el SKILL.md, ejecutar EN ORDEN:

1. **Escribir SKILL.md** en `.claude/skills/<nombre>/SKILL.md`
2. **Copiar a templates** en `templates/skills/<nombre>/SKILL.md` (byte-identico)
3. **Agregar entrada al manifest** en `.claude/config/skills-manifest.json` (skill_counts + array skills)
4. **Regenerar checksums** via `npx tsx bin/lib/version-bump.ts --checksums-only`
5. **Agregar entrada al CHANGELOG** bajo la version actual: `feat(skills): add <nombre> skill`
6. **Presentar resumen** con archivos creados, estado del manifest, y proximos pasos

Detalle completo de cada paso de integracion: `.claude/skills/skill-forge/SKILL.md` seccion "Integracion SDK".

---

## RESUMEN DEL PROTOCOLO

```
/skill-forge [$ARGUMENTS]
  |
  +-- Parsear argumentos (nombre pre-definido o --help)
  |
  +-- ENTREVISTA (5 pasos secuenciales)
  |     Step 1: Nombre y proposito
  |     Step 2: Trigger contexts
  |     Step 3: Patron (unica vs A+B)
  |     Step 4: Metadata ASD
  |     Step 5: Evals (opcional)
  |
  +-- GENERACION
  |     Opcion A: via skill-creator + evals
  |     Opcion B: generacion directa
  |
  +-- INTEGRACION SDK
        [1] .claude/skills/<nombre>/SKILL.md
        [2] templates/skills/<nombre>/SKILL.md
        [3] skills-manifest.json (entrada)
        [4] skills-checksums.json (regenerar)
        [5] CHANGELOG.md (entrada feat)
        [6] Resumen al usuario
```

---

## REGLAS CRITICAS

1. **NO saltar pasos de la entrevista** — cada step requiere input del usuario
2. **Validar nombre** contra patron `[a-z0-9-]{3,50}` antes de continuar
3. **Default es skill unica** — solo A+B si complejidad lo justifica
4. **SKILL.md en skills/ y templates/ DEBEN ser byte-identicos**
5. **Actualizar manifest skill_counts** al agregar la nueva entrada
6. **Checksums DEBEN regenerarse** despues de escribir archivos

---

*ASD SDK v3.18.0 — Skill Forge v1.0.0*
