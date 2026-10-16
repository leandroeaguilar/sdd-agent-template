# sdd-agent-template

[![licencia](https://img.shields.io/badge/licencia-MIT-green)](LICENSE)
[![gate SDD](https://img.shields.io/badge/sdd--gate-28%2F28%20tests-blue)](.claude/hooks/sdd-gate.test.sh)
[![estándar](https://img.shields.io/badge/estándar-AGENTS.md-black)](AGENTS.md)

Plantilla de repositorio para hacer **desarrollo guiado por specs** (*spec-driven development*, SDD) con agentes de IA: el agente escribe qué va a construir, vos lo aprobás, y recién ahí se escribe código. **La aprobación no depende de que el agente se acuerde de pedirla: sin ella, el commit se rechaza.**

Es una plantilla de **repo**, no de agente: la usás para arrancar un proyecto en el que van a trabajar Claude Code, Codex, Gemini CLI, Antigravity o Cursor. Trae el flujo de specs, los controles deterministas de seguridad y la memoria entre sesiones; el lenguaje, el framework y `src/` los ponés vos.

**Qué no es:** no es un framework ni una dependencia de runtime · son archivos que copiás una vez y pasan a ser tuyos · los controles son scripts que devuelven un código de salida, no instrucciones que el agente puede olvidar. Todo en español.

**Índice:** [1. Qué obtenés](#1-qué-obtenés) · [2. Requisitos](#2-requisitos) · [3. Arranque y prueba en 1 min](#3-arranque-y-prueba-en-un-minuto) · [4. Kickoff de tu proyecto](#4-kickoff-de-tu-proyecto) · [5. Cómo es el flujo SDD](#5-cómo-es-el-flujo-sdd) · [6. Qué resuelve](#6-qué-resuelve) · [7. Qué corre y cuándo](#7-qué-corre-y-cuándo) · [8. Modo equipo y agentes en paralelo](#8-más-de-una-persona-y-agentes-en-paralelo) · [9. Límites](#9-límites)

---

## 1. Qué obtenés

```text
tu-proyecto/
├── specs/
│   └── 000-ejemplo/          trinidad SDD: spec.md (qué) → plan.md (cómo) → tasks.md (pasos + evidencia)
├── docs/
│   ├── product/              PRD y decisiones de producto (el agente no lo edita solo)
│   ├── adr/                  decisiones técnicas caras de revertir (Architecture Decision Records)
│   └── BITACORA.md           handoff obligatorio entre sesiones (merge=union para ramas paralelas)
│
├── .claude/
│   ├── agents/               @implementer (construye en hilo limpio) y @reviewer (audita sin editar)
│   ├── hooks/                sdd-gate (+ 28 tests), security-guard, secret-scan, agent-diary, search-sessions
│   └── settings.json         12 reglas deny + hooks de sesión (PreToolUse, PostToolUse, Stop)
├── .githooks/
│   └── pre-commit            el gate universal: rama → flujo SDD → secretos → (tu lint y tus tests)
├── .github/
│   ├── workflows/            verify.yml (gates en el PR) y aviso-de-pr.yml (menciones y alerta de control)
│   └── CODEOWNERS.example    mapa opcional de revisores por zona
│
├── AGENTS.md                 la ley común que leen todos los agentes (stack, comandos, reglas SDD)
├── CLAUDE.md                 importa AGENTS.md y suma lo específico de Claude Code
├── feature_list.json         manifiesto de features y su máquina de estados
├── repo.conf                 gobernanza: REPO_MODE=solo|equipo y rama principal
├── COMO-TRABAJAMOS.example.md acuerdo de equipo en lenguaje llano
├── README.proyecto.md        esqueleto del README de tu proyecto (reemplaza a este archivo en el kickoff)
└── setup.sh                  activa y verifica los git hooks en cada clon
```

---

## 2. Requisitos

| Qué | ¿Obligatorio? | Si falta |
|---|---|---|
| `git` ≥ 2.9 | sí | `.githooks/pre-commit` no se activa (`core.hooksPath`) |
| `bash` | sí (en Windows: Git Bash) | los hooks y `setup.sh` no corren |
| `python3` / `python` | en la práctica sí | `sdd-gate` y `security-guard` quedan en *fail-open* (dejan pasar en vez de romper la sesión) |
| `gh` (GitHub CLI) | no | `pr-notice.sh` sale en silencio al abrir sesión |
| Claude Code | no | los hooks de evento de `.claude/` quedan inertes; **el gate de `git commit`, CI y `AGENTS.md` siguen activos para cualquier agente** |

---

## 3. Arranque y prueba en un minuto

### 1. Crear el repo y activar el gate

Usá el botón **Use this template** en GitHub y cloná tu repositorio (o copiá la carpeta). Después corré `setup.sh`:

```bash
git clone https://github.com/<vos>/<tu-proyecto>.git
cd <tu-proyecto>
bash setup.sh
```

> **Importante:** Sin `bash setup.sh` no corre ningún control local (`core.hooksPath` no viaja con `git clone`). Cada persona que clone el repo tiene que correrlo una vez.

### 2. Probalo en un minuto

Tres comandos para comprobar que las guardas están encendidas antes de escribir una línea de tu proyecto:

```bash
# 1. Corré las 28 verificaciones del gate SDD sobre repos git reales
bash .claude/hooks/sdd-gate.test.sh
# → 28/28 ok

# 2. Comprobá que security-guard bloquea la lectura de .env por shell ANTES de ejecutar
echo '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}' \
  | python3 .claude/hooks/security-guard.py ; echo "exit=$?"
# → exit=2 (bloqueado)

# 3. Comprobá que secret-scan rechaza un secreto en el commit
printf 'AWS_SECRET_ACCESS_KEY=%s%s\n' AKIA 0000000000000000 > fuga.txt
git add -f fuga.txt && git commit -m "prueba"   # → debe FALLAR
git reset && rm fuga.txt
```

---

## 4. Kickoff de tu proyecto

Conviene tener claro qué vas a construir antes de empezar: la plantilla gobierna la ejecución, no piensa el producto.

1. **Escribir el producto** en `docs/product/PRD.md`: qué construís, para quién y cómo sabés que funcionó.
2. **Completar [`AGENTS.md`](AGENTS.md)**: nombre del proyecto, descripción, stack y comandos reales. Borrá los placeholders que no apliquen.
3. **Reemplazar este README:** completá [`README.proyecto.md`](README.proyecto.md) y renombralo a `README.md`.
4. **Inicializar tu stack y cablear lint/tests en tres lugares:**
   - `.githooks/pre-commit` (al final del archivo)
   - `.github/workflows/verify.yml`
   - la línea **Suite completa (cierre)** de `AGENTS.md` (de donde la leen `@implementer` y `@reviewer`).
   *(Hasta que lo hagas, los únicos chequeos automáticos son el gate SDD y el de secretos).*
5. **Definir la primera feature en [`feature_list.json`](feature_list.json):** poné el nombre real del proyecto y reemplazá `000-ejemplo` por tu primera feature en estado `"pending"`.
6. **Abrir tu agente en la carpeta del repo** y pedirle la spec de esa feature: te va a entrevistar si hay dudas de producto, escribir `specs/001-<nombre>/`, pasar el estado a `spec_ready` y frenar a esperar tu aprobación.

> **¿Querés la seguridad y la bitácora pero no el flujo de specs?** Borrá `feature_list.json`: el gate SDD queda inerte y todos los demás controles siguen funcionando.
>
> **Configuración local:** tus permisos personales o carpetas adicionales van en `.claude/settings.local.json` (gitignoreado).

---

## 5. Cómo es el flujo SDD

Cada feature vive en `feature_list.json` con un estado, y en `specs/<feature>/` con tres documentos: `spec.md` (qué y por qué), `plan.md` (cómo) y `tasks.md` (los pasos).

```text
pending ─▶ el agente escribe la spec ─▶ spec_ready ─▶ ⏸ VOS APROBÁS ─▶ in_progress ─▶ @implementer ─▶ @reviewer ─▶ done
```

1. **El agente escribe la spec** y deja la feature en `spec_ready`. Las decisiones técnicas las resuelve y las justifica; las de producto te las pregunta.
2. **Vos la leés y aprobás**, pasando el estado a `in_progress` en su propio commit.
3. **`@implementer` construye** tarea por tarea, en un hilo limpio, con un test por requisito.
4. **`@reviewer` audita** el cambio contra la spec, sin haber escrito nada, y aprueba o devuelve correcciones.
5. **Vos commiteás y cerrás** la feature (`done`).

### Lo que sostiene ese flujo

- **La pausa es un gate.** Con una feature en `spec_ready`, cualquier commit que toque código se rechaza.
- **Aprobar es mover el estado a `in_progress` en su propio commit**, antes del código:
  ```bash
  git commit feature_list.json -m "aprueba: 001-mvp"
  ```
  Si la aprobación entra en el mismo commit que el código, el commit se aprueba a sí mismo: `sdd-gate` lo frena y te muestra el comando exacto.
- **Los requisitos se numeran** (`R1`, `R2`…) usando notación EARS y cada tarea dice cuál cubre. El `@reviewer` lee el test de cada requisito y verifica si fallaría en caso de romperse; que la suite esté en verde no le alcanza.
- **Cada tarea deja evidencia.** `_Hecho:_` registra qué comando se corrió y qué devolvió; `_Pendiente:_` deja escrito qué quedó sin hacer y por qué.
- **Las features grandes se parten en fases.** Se declaran en `plan.md` (qué entrega cada una, de cuál depende, qué archivos toca) y cada fase lleva su `tasks-faseN.md`. Las que no dependen entre sí ni comparten archivos se pueden construir en paralelo, un `@implementer` por fase. La aprobación humana sigue siendo una sola, sobre la feature entera.
- **La verificación de cierre prueba el camino real:** contra qué corrió, al menos un caso de error y los datos de prueba limpios. Si solo se pudo probar contra un sustituto, queda como diferido, no como verificado.
- **No todo necesita spec.** Una feature con `"sdd": false` no pasa por la puerta: sirve para un arreglo chico. Lo que vale la pena pasar siempre por spec es lo que sale caro si sale mal: dinero, permisos, datos de usuarios.

---

## 6. Qué resuelve

| Lo que pasa cuando un agente trabaja suelto en tu repo | Cómo lo frena esta plantilla |
|---|---|
| Empieza a programar algo que no le aprobaste | La spec se escribe primero y `sdd-gate` rechaza cualquier commit de código hasta que la apruebes en un commit propio |
| Construye de más, o algo distinto de lo que pediste | Requisitos numerados (`R1..Rn`), sección de fuera de alcance y un `@reviewer` que rechaza lo que nadie pidió |
| Escribe el código y los tests, y valida sus propios malentendidos | Dos subagentes separados: `@implementer` construye y `@reviewer` audita sin editar |
| Dice «listo» sin haber probado nada | Cada tarea exige evidencia (`_Hecho:_`) y el cierre exige probar el camino real |
| Corre un comando peligroso: lee `.env`, saca datos con `curl`, hace `git push --force` | 12 reglas `deny` en `settings.json` + `security-guard` que inspecciona cada comando Bash/Read **antes** de ejecutarlo |
| Commitea un secreto | `secret-scan.sh` bloquea el commit local y vuelve a correr en cada Pull Request (`verify.yml`) |
| Cada sesión arranca de cero y hay que volver a explicarle todo | `agent-diary.sh` bloquea el cierre de sesión si se editaron archivos y no se dejó handoff en `docs/BITACORA.md` |
| Las reglas viven en un archivo que solo lee una herramienta | [`AGENTS.md`](AGENTS.md), el estándar abierto que leen todos los agentes |
| Entra una segunda persona y nadie sabe quién toca qué | `REPO_MODE=equipo`: gate de rama en `pre-commit`, acuerdo `COMO-TRABAJAMOS.md` y avisos de PR |

---

## 7. Qué corre y cuándo

**Harness:** `CC` = solo dentro de Claude Code. `todos` = cualquier agente (Codex, Gemini CLI, Antigravity, Cursor, Claude Code) y humanos.

| Pieza | Se dispara con | Harness | Kill-switch (`.repo-meta/…`) |
|---|---|---|---|
| `pr-notice.sh` | inicio de sesión (`SessionStart`) | CC | `pr-notice.disabled` |
| `security-guard.sh` + `.py` | antes de `Bash` o `Read` (`PreToolUse`) | CC | `security-guard.disabled` |
| `session-touch.sh` | después de `Edit`/`Write` (`PostToolUse`) | CC | — |
| `agent-diary.sh` | cierre de sesión (`Stop`) | CC | `diary.disabled` |
| `check-diary-size.sh` | lo llama `agent-diary.sh` | CC | `diary-cap.disabled` |
| `search-sessions.py` | bajo demanda (CLI) | todos | — |
| gate de rama (`REPO_MODE=equipo`) | `git commit` (`.githooks/pre-commit`) | todos | `branch-gate.disabled` |
| `sdd-gate.sh` + `.py` | `git commit` + CI | todos | `sdd-gate.disabled` |
| `secret-scan.sh` | `git commit` + CI | todos | `secret-scan.disabled` |
| `verify.yml` · `aviso-de-pr.yml` | Pull Request en GitHub | todos | desactivar el workflow |

---

## 8. Más de una persona y agentes en paralelo

### Modo equipo (`REPO_MODE=equipo`)

Con un solo dueño esta capa no hace nada (`REPO_MODE=solo` por defecto). Cuando entra la segunda persona:

1. **Cambiar a `REPO_MODE=equipo` en [`repo.conf`](repo.conf).** Desde ese commit, `.githooks/pre-commit` bloquea todo commit directo sobre `main`: todo entra por PR.
2. **Completar [`COMO-TRABAJAMOS.example.md`](COMO-TRABAJAMOS.example.md) y renombrarlo a `COMO-TRABAJAMOS.md`.** Es lo que la persona nueva lee en diez minutos antes de su primer commit (prefijos de rama de dos letras, zonas, secretos).
3. **`cp .github/CODEOWNERS.example .github/CODEOWNERS`** con los usuarios reales, si aplica (ver aviso abajo).
4. **Cada persona corre `bash setup.sh` en su clon.** El script aborta si el gate local no queda activo.
5. **Reglas de rama en GitHub** (*Settings → Rules*, sobre `main`): exigir PR, revisión de Code Owners, el check `verify` y bloquear force-push.

> [!WARNING]
> **El paso 5 no existe en plan GitHub Free con repositorio privado.** La API responde `403 · "Upgrade to GitHub Pro or make this repository public"`.
>
> | Pieza | En GitHub Free + repo privado |
> |---|---|
> | Rama por persona + PR | ✅ funciona por convención |
> | `verify.yml` en el PR | ✅ corre, pero es señal y no bloqueo: un PR en rojo se puede mergear igual |
> | Exigir PR, revisión de Code Owners, status checks y bloqueo de force-push | ❌ no disponibles en el servidor |
> | Gate de rama del `.githooks/pre-commit` | ✅ **el único control automático real** |
>
> Si estás en Free + privado, el paso 4 (`bash setup.sh` en cada máquina, verificable con `git config core.hooksPath`) y el acuerdo `COMO-TRABAJAMOS.md` son los controles reales.

### Varios agentes en paralelo

Usá un worktree físico por agente:

```bash
git worktree add -b agent/<nombre> ../<proyecto>-<nombre>
```

Cada worktree tiene su propio checkout y su propio `.repo-meta/`. `docs/BITACORA.md` tiene configurado `merge=union` en `.gitattributes`, así que dos handoffs simultáneos no dan conflicto de merge; por eso cada entrada lleva **agente y rama** en el encabezado. Las reglas completas están en [`AGENTS.md`](AGENTS.md).

---

## 9. Límites

- **Los hooks de `.claude/` solo corren en Claude Code.** Para cualquier otro agente, el control automático es el gate de `git commit` (`.githooks/pre-commit`). La prevención de lectura de credenciales o `curl` por shell fuera de Claude Code depende del criterio del agente y del entorno.
- **El gate de commit se puede saltear** con `--no-verify` y cada hook tiene un kill-switch en `.repo-meta/`. Es deliberado: el control hace que saltearlo sea un acto explícito y visible, no que sea imposible.
- **Una feature que nunca entra a `feature_list.json` no está protegida por SDD.** El gate reacciona a `spec_ready` e `in_progress`; si nadie registra la feature, no hay puerta.
- **El manifiesto lo puede editar un agente.** Lo que `sdd-gate` garantiza es que la transición a `in_progress` quede aislada y fechada en su propio commit sin código, no quién tipeó el comando.
- **El `@reviewer` es de solo lectura por instrucción**, no por restricción de sistema de archivos.
- **Sin tu suite de tests cableada (paso 4 del kickoff), `verify` da verde validando solo specs y secretos.**

---

## Ideas en las que se apoya

El estándar [AGENTS.md](https://agents.md), el flujo `spec → plan → tasks` de [github/spec-kit](https://github.com/github/spec-kit), la notación EARS para requisitos y el frontmatter [OKF v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog) para la documentación.

## Licencia

[MIT](LICENSE) © 2026 Leandro Aguilar.
