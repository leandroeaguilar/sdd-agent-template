# CLAUDE.md — [NOMBRE DEL PROYECTO]

La ley de este repo vive en un solo lugar: @AGENTS.md

## Específico de Claude Code

- Cambios multi-archivo o de enfoque incierto: plan mode primero (Explore → Plan → Implement → Commit). Fixes de una línea: directo.
- Features con `"sdd": true`: entrevistame con AskUserQuestion hasta cubrir los casos difíciles → **leé el código real** antes de planificar (va a `plan.md` §Estado actual; no asumas desde un doc viejo) → escribí la spec (`spec.md` con EARS `R1..Rn`, `plan.md`, `tasks.md` con `T1..Tn`) → cambiá el estado a `spec_ready` en `feature_list.json` y **pedí aprobación**. Las decisiones técnicas ambiguas las resolvés vos en `plan.md`; las de negocio van a `spec.md` §Preguntas abiertas y **bloquean el `spec_ready`**. Al pedir aprobación, resumí solo lo no obvio, no repitas la spec.
- Feature grande: partila en fases en `plan.md` §Fases, con un `tasks-faseN.md` por fase. La aprobación sigue siendo una sola.
- Tras la aprobación (la da el humano, no vos): despachá al subagente `@implementer` para construir las tareas en contexto fresco. Con fases: **un `@implementer` por fase**, diciéndole cuál es la suya; las que no dependen entre sí ni comparten archivos van en el mismo mensaje (paralelo), las demás recién cuando cierra la anterior. Si comparten un contrato, tiene que estar escrito en `plan.md` antes de despachar.
- Cuando terminan, **no les creas el informe**: corré vos la suite completa de `AGENTS.md` y, si hubo paralelo, verificá que todas las fases respetaron el contrato.
- Antes de commitear, **las dos cosas** — miran problemas distintos y ninguna cubre a la otra:
  - `@reviewer` → **¿cumple la spec?** Trazabilidad `R<n>` ↔ test, fuera de alcance, `AGENTS.md`.
  - `/code-review` → **¿tiene bugs?** Correctitud, en contexto fresco. Una feature puede satisfacer los cuatro requisitos EARS y tener un off-by-one.
- Para probar end-to-end antes de un commit importante: `/verify`. Antes de levantar un servidor, mirá qué puertos ya usa el humano y elegí otro; al terminar bajá solo los tuyos. Si no pudiste probar contra el motor real, decilo como *diferido* — nunca como verificado.
- Investigaciones amplias del codebase: subagentes, para no llenar el contexto principal.
