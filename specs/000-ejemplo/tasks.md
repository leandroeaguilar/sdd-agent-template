---
type: Tasks
title: "Tasks 000 — [nombre de la feature]"
description: "[Una oración: los pasos para construir la feature de plan.md.]"
generated:
  by: process:claude-code
  at: 2026-11-14T00:00:00Z
---

# Tasks 000 — [nombre de la feature]

> Pasos chicos e iterativos, **sin saltos de complejidad** entre uno y el siguiente.
> Cada task debe indicar qué requisito `R<n>` o invariante `P<n>` de `spec.md` satisface y cerrar con su verificación (test en verde).
> **Los tests van primero y los escribe otro.** La `T1` es del `@tester`: un test por `R<n>` y una propiedad por `P<n>`, en rojo, con el hash de cada archivo en su `_Hecho:_`. El `@implementer` no toca esos archivos — los pone en verde. (Si `plan.md` declara la excepción al `@tester`, borrá la `T1` y cada tarea lleva su propio test.)
> El test tiene que **fallar si el requisito se rompe** — uno que solo comprueba que el código no explota no cuenta como cobertura.
> El `@implementer` marca `[x]` al terminar cada paso; el `@reviewer` verifica que no queden tasks `[ ]`.
> **Cada tarea deja evidencia**, no solo la casilla: `_Hecho:_` dice qué se corrió y qué devolvió; `_Pendiente:_` dice qué quedó sin hacer y por qué. Una tarea bloqueada queda `[ ]` con su `_Pendiente:_` — nunca `[x]` "para avanzar".
> **Feature por fases** (ver `plan.md` §Fases): este archivo se reemplaza por uno por fase — `tasks-fase1.md`, `tasks-fase2.md`… — con este mismo formato. La numeración `T<n>` sigue de largo entre fases, para que cada tarea tenga un nombre único. La tarea del `@tester` va **una sola vez**, en `tasks-fase1.md`, y cubre los `R<n>` / `P<n>` de todas las fases y el contrato compartido.

- [ ] **T1 (`@tester`):** Tests en rojo de R1..R4 y propiedades de P1 (Cubre: R1, R2, R3, R4, P1) — **Verifica:** `[comando de tests]` falla en cada uno por comportamiento ausente, no por error del test
  - _Hecho:_ [comando y resultado · qué test cubre cada R/P · un `git hash-object <ruta>` por archivo de test]
  - _Pendiente:_
- [ ] **T2:** [Implementar modelo/migración de datos] (Cubre: R1, P1) — **Verifica:** `[comando del test puntual]`
  - _Hecho:_
  - _Pendiente:_
- [ ] **T3:** [Implementar lógica de negocio o servicio] (Cubre: R2, R4) — **Verifica:** `[comando del test puntual]`
  - _Hecho:_
  - _Pendiente:_
- [ ] **T4:** [Implementar endpoint/interfaz de usuario] (Cubre: R3) — **Verifica:** `[comando del test puntual]`
  - _Hecho:_
  - _Pendiente:_
- [ ] **T5:** [Cierre: suite completa, linter y mutación] — **Verifica:** el comando de *suite completa* de `AGENTS.md` y, si está cableado, el de *mutación* sobre los archivos de esta feature
  - _Hecho:_ [además del resultado: cada mutante sobreviviente, y si se mató con un test nuevo o por qué es equivalente]
  - _Pendiente:_
