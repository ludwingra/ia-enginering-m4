---
name: release
description: "Validate and create a semver release — bumps version, updates changelog, creates git tag"
---

# Comando /release — Release Manager — ASD SDK

> **Uso:** `/release` para iniciar el flujo interactivo de release.
> **Restriccion:** Ejecutar solo desde el branch `develop` o un branch de release.

---

## FLUJO DE RELEASE

Al ejecutar `/release`, segui estos pasos exactos en orden:

### STEP 1 — Preguntar tipo de bump

Pregunta al usuario que tipo de release quiere crear:

```
Que tipo de release vas a crear?

  [1] patch   — Bug fixes, mejoras de prompt, performance
  [2] minor   — Nuevas features, agentes, skills, hooks, commands
  [3] major   — Breaking changes en CLI, flags, schema de archivos generados, nombres de agentes/commands
  [4] prerelease — Release candidate (rc.N) para testing

(Politica ADR-012: https://github.com/ludwingra/sdk-sdd/blob/main/.claude/memory/TECH_DECISIONS.md)
```

Espera la respuesta del usuario antes de continuar.

### STEP 2 — Leer estado actual

Lee la version actual y el changelog:

1. Lee `package.json` del proyecto y extrae el campo `version`
2. Lee `bin/lib/types.ts` y extrae el valor de `SDK_VERSION` — verifica que coincida con package.json
3. Lee `CHANGELOG.md` y extrae el contenido bajo `## [Unreleased]`
4. Calcula la nueva version aplicando la logica de `bumpVersion()` de `bin/lib/version-bump.ts`:
   - `patch`: incrementa patch, remueve prerelease
   - `minor`: incrementa minor, resetea patch a 0, remueve prerelease
   - `major`: incrementa major, resetea minor y patch a 0, remueve prerelease
   - `prerelease`: agrega o incrementa sufijo `-rc.N`

### STEP 3 — Mostrar preview

Muestra al usuario un resumen claro:

```
--- Release Preview ---

  Version actual:  X.Y.Z
  Version nueva:   X.Y.Z (tipo: [patch|minor|major|prerelease])

  Changelog [Unreleased]:
  ────────────────────────
  [contenido de la seccion Unreleased]
  ────────────────────────

  Archivos que se modificaran:
    - package.json (version)
    - bin/lib/types.ts (SDK_VERSION)
    - CHANGELOG.md ([Unreleased] -> [X.Y.Z] - YYYY-MM-DD)

  Se creara:
    - Git commit: "chore: release vX.Y.Z"
    - Git tag anotado: vX.Y.Z
```

### STEP 4 — Pedir confirmacion

Pregunta:

```
Confirmas el release vX.Y.Z? (S/N)
```

Si el usuario responde N o cancela, aborta sin hacer cambios.

### STEP 5 — Ejecutar validacion pre-release

Antes de hacer cambios, valida la coherencia actual del proyecto:

1. Ejecuta `git status --porcelain` — el working tree debe estar limpio
2. Verifica que `package.json` version === `SDK_VERSION` en types.ts
3. Verifica que NO exista un git tag `vX.Y.Z` para la nueva version
4. Verifica que CHANGELOG.md tenga seccion `## [Unreleased]`

Si alguna validacion falla, muestra los errores y aborta. No continua parcialmente.

### STEP 6 — Ejecutar cambios

Ejecuta en este orden exacto:

1. **Actualizar package.json** — cambia el campo `"version"` al nuevo valor
2. **Actualizar bin/lib/types.ts** — reemplaza el valor de `SDK_VERSION` con la nueva version usando regex: `/^(export const SDK_VERSION\s*=\s*')[^']*(')/m`
3. **Actualizar CHANGELOG.md** — promueve la seccion `## [Unreleased]` a `## [X.Y.Z] - YYYY-MM-DD` (fecha de hoy), e inserta una nueva seccion `## [Unreleased]` vacia arriba con un separador `---`
4. **Crear commit:**
   ```bash
   git add package.json bin/lib/types.ts CHANGELOG.md
   git commit -m "chore: release vX.Y.Z"
   ```
5. **Crear tag anotado:**
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   ```

### STEP 7 — Mostrar resumen final

```
--- Release Completado ---

  Tag:     vX.Y.Z
  Commit:  [SHA corto]
  Branch:  [branch actual]

  Changelog promovido:
  [contenido de la seccion que se promovio]

  Proximos pasos:
    1. git push origin [branch]
    2. git push origin vX.Y.Z
    3. Crear PR a main si corresponde
```

---

## REGLAS

- NO ejecutes nada sin confirmacion explicita del usuario en STEP 4
- Si el working tree esta sucio, sugeri hacer commit o stash antes de continuar
- Usa las funciones de `bin/lib/version-bump.ts` como referencia para la logica, pero ejecuta las operaciones directamente (leer/escribir archivos, ejecutar git)
- El formato de fecha para el changelog es YYYY-MM-DD (ISO 8601)
- El tag siempre lleva prefijo `v`: `v3.6.0`, `v3.6.0-rc.1`

---

*ASD SDK — Release Manager*
