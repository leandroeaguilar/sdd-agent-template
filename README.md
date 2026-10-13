# sdd-agent-template

Plantilla de repo para hacer **desarrollo guiado por specs** (*spec-driven development*, SDD) con agentes de IA: el agente escribe qué va a construir, vos lo aprobás, y recién ahí se escribe código. La aprobación no depende de que el agente se acuerde de pedirla: sin ella, el commit se rechaza.

Es una plantilla de **repo**, no de agente: la copiás para empezar un proyecto en el que van a trabajar Claude Code, Codex, Gemini CLI o Cursor. Trae el flujo de specs, los controles de seguridad y la memoria entre sesiones; el lenguaje, el framework y `src/` los ponés vos.

No es un framework ni una dependencia: son archivos que copiás una vez y pasan a ser tuyos. Todo en español.

## Qué resuelve

| Lo que pasa cuando un agente trabaja en tu repo | Cómo lo frena esta plantilla |
|---|---|
| Empieza a programar algo que no le aprobaste | La spec se escribe primero y el commit de código se rechaza hasta que vos la apruebes |
| Construye de más, o algo distinto de lo que pediste | Requisitos numerados, una sección de fuera de alcance y un revisor que rechaza lo que nadie pidió |
| Escribe el código y los tests, y valida sus propios malentendidos | Dos subagentes: uno construye, otro audita sin haber escrito nada |
| Dice "listo" sin haber probado nada | Cada tarea deja qué se corrió y qué devolvió, y el cierre exige probar el camino real |
| Corre un comando que no debía: lee tu `.env`, saca datos con `curl`, hace `git push --force` | Lista de permisos denegados + un hook que revisa cada comando **antes** de ejecutarlo |
| Commitea un secreto | Escaneo de secretos en cada commit, y otra vez en cada PR |
| Cada sesión arranca de cero y hay que volver a explicarle todo | Bitácora de handoff que el agente tiene que completar antes de cerrar |
| Las reglas viven en un archivo que solo lee una herramienta | `AGENTS.md`, el estándar que leen todos los agentes |
| Entra una segunda persona y nadie sabe quién toca qué | Modo equipo: gate de rama, acuerdo de trabajo y avisos de PR |

Los controles son scripts que devuelven un código de salida, no instrucciones que el agente puede olvidar. Lo que sí es solo una convención está dicho en [Límites](#límites).

## Cómo es el flujo

Cada feature vive en `feature_list.json` con un estado, y en `specs/<feature>/` con tres documentos: `spec.md` (qué y por qué), `plan.md` (cómo) y `tasks.md` (los pasos).

```
pending ─▶ el agente escribe la spec ─▶ spec_ready ─▶ ⏸ VOS APROBÁS ─▶ in_progress ─▶ @implementer ─▶ @reviewer ─▶ done
```

1. **El agente escribe la spec** y deja la feature en `spec_ready`. Las decisiones técnicas las resuelve y las justifica; las de producto te las pregunta.
2. **Vos la leés y aprobás**, pasando el estado a `in_progress`.
3. **`@implementer` construye** tarea por tarea, en un hilo limpio, con un test por requisito.
4. **`@reviewer` audita** el cambio contra la spec, sin haber escrito nada, y aprueba o devuelve correcciones.
5. **Vos commiteás y cerrás** la feature.

Lo que sostiene ese flujo:

- **La pausa es un gate.** Con una feature en `spec_ready`, cualquier commit que toque código se rechaza.
- **Aprobar es mover el estado a `in_progress`, en su propio commit**, antes del código:
  ```
  git commit feature_list.json -m "aprueba: 001-mvp"
  ```
  Si la aprobación entra junto con el código, el commit se aprueba a sí mismo. El gate lo frena y te muestra el comando.
- **Los requisitos se numeran** (`R1`, `R2`…) y cada tarea dice cuál cubre. El `@reviewer` lee el test de cada requisito y responde si fallaría en caso de romperse; que la suite esté en verde no le alcanza.
- **Cada tarea deja evidencia.** `_Hecho:_` dice qué se corrió y qué devolvió; `_Pendiente:_` dice qué quedó sin hacer y por qué.
- **Las features grandes se parten en fases.** Se declaran en `plan.md` (qué entrega cada una, de cuál depende, qué archivos toca) y cada fase lleva su `tasks-faseN.md`. Las que no dependen entre sí ni comparten archivos se pueden construir en paralelo, un `@implementer` por fase. La aprobación es una sola, sobre la feature entera.
- **La verificación de cierre prueba el camino real**: contra qué corrió, al menos un caso de error, y los datos de prueba limpios. Si solo se pudo probar contra un sustituto, queda como diferido, no como verificado.
- **No todo necesita spec.** Una feature con `"sdd": false` no pasa por la puerta: sirve para un arreglo chico. Lo que vale la pena pasar siempre es lo que sale caro si sale mal: dinero, permisos, datos de usuarios.

## Qué trae

**Flujo de specs**

| Pieza | Qué hace |
|---|---|
| `feature_list.json` | Manifiesto de features y su estado: qué se está construyendo y qué espera tu aprobación |
| `specs/000-ejemplo/` | Esqueleto de una feature: `spec.md` (qué) → `plan.md` (cómo) → `tasks.md` (pasos, cada uno con su evidencia) |
| `sdd-gate` | Rechaza el commit si se toca código con una spec sin aprobar, si hay dos features en curso o si se cierra una con tareas abiertas. Tests: `bash .claude/hooks/sdd-gate.test.sh` (28 verificaciones sobre repos git reales) |
| `.claude/agents/` | `@implementer` construye en un hilo limpio; `@reviewer` audita el cambio contra la spec y no edita |

**Reglas del repo**

| Pieza | Qué hace |
|---|---|
| `AGENTS.md` | La ley del repo: stack, comandos, convenciones, flujo de trabajo y seguridad. La completás en el arranque |
| `CLAUDE.md` | Importa `AGENTS.md` y suma lo específico de Claude Code |
| `repo.conf` | `REPO_MODE=solo\|equipo`: cambia quién firma los commits y si se puede commitear a `main` |

**Seguridad**

| Pieza | Qué hace |
|---|---|
| `.claude/settings.json` | Permisos denegados: leer `.env` y claves, `curl`/`wget`, force-push, salir de la carpeta del repo |
| `security-guard` | Hook previo a cada comando. Ataja lo que la lista de permisos no ve porque solo mira el principio del comando: un `curl` a mitad de línea, un `cat .env`, una escritura por redirección a `.claude/` |
| `secret-scan` | Bloquea el commit si hay un secreto staged. Corre también en CI sobre el rango del PR |
| `.githooks/pre-commit` | El gate de cada commit, donde se apoya todo lo demás: rama → flujo de specs → secretos → (tu lint y tus tests) |
| `.gitignore` + `.env.example` | Secretos fuera del repo desde el primer día |

**Memoria entre sesiones**

| Pieza | Qué hace |
|---|---|
| `docs/BITACORA.md` | Handoff entre sesiones. Si la sesión editó archivos, el agente no puede cerrar sin dejar su entrada |
| `check-diary-size` | Cuando la bitácora crece demasiado, pide proponer una consolidación. No borra ni bloquea |
| `search-sessions.py` | Busca en las sesiones pasadas de Claude Code de este repo: el error exacto, el comando que falló. Solo ve tus sesiones en tu máquina |
| `docs/adr/` | Decisiones técnicas caras de revertir, una por archivo |
| `docs/product/` | El PRD y las decisiones de producto |

**Más de una persona**

| Pieza | Qué hace |
|---|---|
| `COMO-TRABAJAMOS.example.md` | Acuerdo de trabajo en lenguaje llano: ramas, zonas, secretos, qué hacer si algo sale mal |
| `pr-notice` | Al abrir una sesión, avisa qué PRs esperan tu revisión |
| `.github/workflows/aviso-de-pr.yml` | Menciona al revisor en cada PR y marca si toca archivos que cambian el comportamiento de los agentes |
| `.github/workflows/verify.yml` | Los mismos chequeos del commit, del lado del servidor |
| `.github/CODEOWNERS.example` | Quién revisa qué. No restringe quién escribe |

**Arranque**

| Pieza | Qué hace |
|---|---|
| `setup.sh` | Activa el gate de commit en tu clon y verifica que quedó activo |
| `README.proyecto.md` | Esqueleto del README de tu proyecto; reemplaza a este |
| `.gitattributes` | Fuerza LF en los hooks: con CRLF se rompen en Windows |

## Cómo usarlo

**Requisitos:** [Git](https://git-scm.com) (con Git Bash en Windows) y Python, que usan los hooks. Un agente de código para aprovecharlo; los hooks de `.claude/` son específicos de [Claude Code](https://claude.com/claude-code).

Conviene tener escrito qué vas a construir antes de empezar. El repo no piensa el producto.

1. **Crear tu repo.** Con el botón **Use this template** de GitHub, y cloná el resultado. O copiá la carpeta y borrá el `.git/` copiado.
2. **Correr `bash setup.sh`.** Activa el gate de commit. Sin este paso no corre ningún control: la configuración de hooks es local y no viaja con el repo. Cada persona que clone tiene que correrlo.
3. **Escribir el producto** en `docs/product/PRD.md`: qué construís, para quién y cómo sabés que funcionó.
4. **Completar `AGENTS.md`**: nombre, descripción, stack y comandos reales. Borrá los placeholders que no apliquen.
5. **Completar `README.proyecto.md` y renombrarlo a `README.md`**, pisando este archivo.
6. **Elegir el stack e inicializarlo.** Después cableá tu lint y tus tests en tres lugares: `.githooks/pre-commit`, `.github/workflows/verify.yml` y la línea *Suite completa* de `AGENTS.md`, que es de donde los leen los subagentes. Hasta que lo hagas, el único chequeo que corre es el de secretos.
7. **Definir la primera feature.** Poné el nombre del proyecto en `feature_list.json` y reemplazá la feature de ejemplo por la tuya, en estado `pending`.
8. **Abrir el agente desde la carpeta del repo** y pedirle la spec de esa feature. Te va a entrevistar, escribir `specs/001-<nombre>/` y frenar a esperar tu aprobación.

Lo personal de tu máquina (permisos propios, carpetas adicionales) va en `.claude/settings.local.json`, que no se commitea.

Si querés la seguridad y la bitácora pero no el flujo de specs, borrá `feature_list.json`: el gate de specs queda inerte y el resto sigue funcionando.

## Más de una persona en el repo

Con un solo dueño esta capa no hace nada: `REPO_MODE=solo` es el valor por defecto. Cuando entra la segunda persona:

1. **`REPO_MODE=equipo` en `repo.conf`.** Desde ese commit no se puede commitear directo a `main`: todo entra por PR.
2. **Completar `COMO-TRABAJAMOS.example.md` y renombrarlo a `COMO-TRABAJAMOS.md`.** Es lo que la persona nueva lee en diez minutos antes de su primer commit.
3. **`cp .github/CODEOWNERS.example .github/CODEOWNERS`** con los usuarios reales, si te va a servir (ver el aviso).
4. **Cada persona corre `bash setup.sh` en su clon.** El script aborta si el gate no queda activo.
5. **Reglas de rama en GitHub** (Settings → Rules, sobre `main`): exigir PR, revisión de Code Owners, el check `verify` y bloquear force-push. Este paso no se puede hacer desde el repo.

> [!WARNING]
> **El paso 5 no existe en plan Free con repo privado.** La API responde `403 · "Upgrade to GitHub Pro or make this repository public"`. Verificado el 2026-08-06.
>
> | Pieza | En Free + privado |
> |---|---|
> | Rama por persona + PR | ✅ funciona, es una convención |
> | `verify.yml` en el PR | ✅ corre, pero es señal y no bloqueo: un PR en rojo se mergea igual |
> | Exigir PR, revisión de Code Owners, checks, bloqueo de force-push | ❌ no disponibles |
> | Gate de rama del `pre-commit` | ✅ el único control automático real |
>
> En ese escenario `CODEOWNERS` no restringe nada y tampoco asigna revisor. Las salidas son tres: pasar a un plan pago, hacer público el repo, o aceptar la convención a conciencia. La tercera funciona con dos personas que se hablan.

El gate local se activa por clon y se saltea con `--no-verify`. Si el servidor no puede ayudar, el paso 4 es el crítico: verificalo con `git config core.hooksPath`, que tiene que devolver `.githooks`.

## Varios agentes en paralelo

Un worktree por agente: `git worktree add -b agent/<nombre> ../<proyecto>-<nombre>`. Cada uno tiene su propio checkout y sus propias marcas de sesión. `docs/BITACORA.md` se mergea por unión, así que dos handoffs simultáneos no dan conflicto; por eso cada entrada lleva agente y rama en el encabezado. Las reglas completas están en `AGENTS.md`.

## Límites

- **Los hooks de `.claude/` solo corren en Claude Code.** Para cualquier otro agente, lo único que corre es el gate de `git commit`. El control de comandos y de lectura de credenciales no tiene equivalente ahí.
- **El gate de commit se saltea** con `--no-verify` y cada hook tiene un interruptor en `.repo-meta/`. Es deliberado: el control hace que saltearlo sea un acto visible, no que sea imposible.
- **Una feature que nunca entra al manifiesto no está protegida.** El gate reacciona a `spec_ready`; si nadie escribe la spec, no hay puerta.
- **El manifiesto lo puede editar un agente.** Lo que el gate garantiza es que la aprobación quede fechada en un commit aparte, no quién la firmó.
- **El `@reviewer` es de solo lectura por instrucción**, no por permisos.
- **Sin tu suite cableada, `verify` da verde sin haber probado nada.**

## Ideas en las que se apoya

El estándar [AGENTS.md](https://agents.md), el flujo spec → plan → tasks de [github/spec-kit](https://github.com/github/spec-kit), la notación EARS para requisitos y el frontmatter [OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog) para los documentos.

## Licencia

[MIT](LICENSE) © 2026 Leandro Aguilar.
