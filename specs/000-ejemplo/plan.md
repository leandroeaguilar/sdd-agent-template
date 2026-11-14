---
type: Plan
title: "Plan 000 — [nombre de la feature]"
description: "[Una oración: cómo se implementa la feature de spec.md.]"
generated:
  by: process:claude-code
  at: 2026-11-14T00:00:00Z
---

# Plan 000 — [nombre de la feature]

> El CÓMO técnico: arquitectura, archivos a tocar, contratos de datos, dependencias y riesgos. Deriva de `spec.md`.

## Estado actual
[Qué ya existe en el código y **no hay que rehacer**, con rutas. Se escribe después de leer los módulos reales, no desde un doc viejo ni desde memoria: es lo que evita que el `@implementer` reconstruya algo que ya estaba.]

## Enfoque
[Arquitectura de la solución en 3-5 líneas: patrón de diseño, capas involucradas.]

## Archivos e interfaces
[Qué se crea/modifica, con rutas exactas:]
- `src/models/...` — [nuevo/modificado]
- `src/services/...` — [nuevo/modificado]
- `tests/...` — [tests de R1..Rn y propiedades de P1..Pn: los escribe el `@tester` **desde estas rutas y firmas**, antes de que exista la implementación. Una interfaz que no esté fijada acá, el `@tester` no la puede testear.]

## Modelo de datos
[Tablas/campos/relaciones nuevos o modificados. Omitir si la feature no toca base de datos.]

## Integraciones y contratos
[APIs, servicios externos o librerías nuevas, con sus modos de fallo y timeouts.]

## Decisiones de diseño
> Las ambigüedades técnicas se resuelven **acá**, antes de delegar — no se las deja al `@implementer`. Numeradas, cada una con su porqué. (Las de negocio no van acá: son `## Preguntas abiertas` de `spec.md`.)

1. **[Decisión]** — [justificación en una línea].

> **Excepción al `@tester`.** Por defecto los tests los escribe el `@tester`, en rojo, antes del `@implementer`. Si esta feature no tiene comportamiento que testear (solo documentación, solo configuración), se declara acá como una decisión más, con su porqué — el humano la ve al aprobar. Sin esa línea, `@implementer` y `@reviewer` asumen que el `@tester` corre.

## Fases
> **Opcional.** Solo si la feature es grande y se parte en bloques entregables y verificables por separado. Si no, borrá esta sección y usá un único `tasks.md`.
> Con fases, cada una lleva su archivo `tasks-faseN.md` (en lugar de `tasks.md`) y la aprobación humana sigue siendo **una sola**, sobre la feature entera.

| Fase | Entrega | Depende de | Archivos que toca | Tareas |
|---|---|---|---|---|
| 1 | [qué queda funcionando] | — | `src/...` | `tasks-fase1.md` |
| 2 | [qué queda funcionando] | 1 | `src/...` | `tasks-fase2.md` |

- **Dependencias reales, no orden arbitrario.** Dos fases sin dependencia entre sí **y sin archivos en común** pueden construirse en paralelo; si comparten un archivo, van en serie (ver `AGENTS.md`, *Serializá los hotspots*).
- **Contrato compartido.** Si una fase expone algo que otra consume (rutas, forma de request/response, códigos de error), se fija acá, textual. Dos agentes en paralelo no se ven entre sí: lo que no esté escrito, lo inventa cada uno distinto.

## Riesgos y alternativas descartadas
[Qué alternativas técnicas se evaluaron y por qué se descartaron. Si una decisión es cara de revertir → crear `docs/adr/`.]
