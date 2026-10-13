---
type: Tasks
title: "Tasks 000 — [nombre de la feature]"
description: "[Una oración: los pasos para construir la feature de plan.md.]"
generated:
  by: process:claude-code
  at: 2026-10-13T00:00:00Z
---

# Tasks 000 — [nombre de la feature]

> Pasos chicos e iterativos, **sin saltos de complejidad** entre uno y el siguiente.
> Cada task debe indicar qué requisito `R<n>` de `spec.md` satisface y cerrar con su verificación (test en verde).
> El test tiene que **fallar si el requisito se rompe** — uno que solo comprueba que el código no explota no cuenta como cobertura.
> El `@implementer` marca `[x]` al terminar cada paso; el `@reviewer` verifica que no queden tasks `[ ]`.
> **Cada tarea deja evidencia**, no solo la casilla: `_Hecho:_` dice qué se corrió y qué devolvió; `_Pendiente:_` dice qué quedó sin hacer y por qué. Una tarea bloqueada queda `[ ]` con su `_Pendiente:_` — nunca `[x]` "para avanzar".
> **Feature por fases** (ver `plan.md` §Fases): este archivo se reemplaza por uno por fase — `tasks-fase1.md`, `tasks-fase2.md`… — con este mismo formato. La numeración `T<n>` sigue de largo entre fases, para que cada tarea tenga un nombre único.

- [ ] **T1:** [Implementar modelo/migración de datos] (Cubre: R1) — **Verifica:** `[comando del test puntual]`
  - _Hecho:_
  - _Pendiente:_
- [ ] **T2:** [Implementar lógica de negocio o servicio] (Cubre: R2, R4) — **Verifica:** `[comando del test puntual]`
  - _Hecho:_
  - _Pendiente:_
- [ ] **T3:** [Implementar endpoint/interfaz de usuario] (Cubre: R3) — **Verifica:** `[comando del test puntual]`
  - _Hecho:_
  - _Pendiente:_
- [ ] **T4:** [Cierre: suite completa y linter] — **Verifica:** el comando de *suite completa* de `AGENTS.md`
  - _Hecho:_
  - _Pendiente:_
