---
type: Spec
title: "Spec 000 — [nombre de la feature]"
description: "[Una oración: qué feature especifica este documento.]"
generated:
  by: process:claude-code
  at: 2026-10-13T00:00:00Z
---

# Spec 000 — [nombre de la feature]

> El QUÉ y el POR QUÉ. Sin detalles de implementación (eso va en plan.md).
> Esqueleto de ejemplo — borrar esta carpeta al crear specs/001-<feature>/ real.

## Problema
[Qué necesidad de usuario o negocio resuelve, para quién.]

## Usuario objetivo
[Quién lo usa, en 2-3 frases. Si hay varios roles (ej. admin vs visitante), listalos.]

## Comportamiento esperado (Requisitos EARS)
> Cada requisito funcional se numera (`R1`, `R2`...) y se redacta en sintaxis EARS (*Easy Approach to Requirements Syntax*) para eliminar ambigüedades.

- **R1 (Ubicuo / Regla Permanente):** El sistema DEBE [comportamiento universal].
- **R2 (Disparado por Evento):** CUANDO [evento del usuario o sistema], el sistema DEBE [respuesta esperada].
- **R3 (Basado en Estado):** MIENTRAS [estado operativo activo], el sistema DEBE [respuesta continua].
- **R4 (Manejo de Excepción / Error):** SI [condición de fallo o dato inválido], ENTONCES el sistema DEBE [respuesta de contingencia].

## Preguntas abiertas
> Decisiones de **negocio o producto** que el agente no puede tomar solo. Una pregunta escrita acá es un freno: la spec no pasa a `spec_ready` hasta que el humano la responda. Las decisiones puramente técnicas no van acá — se resuelven y se justifican en `plan.md`.

- [Pregunta concreta, con las opciones y qué cambia según la respuesta. Si no hay ninguna: «Ninguna».]

## Fuera de alcance
[Qué NO incluye esta feature en esta iteración — barrera explícita para evitar que los agentes alucinen funcionalidades de más.]

## Verificación de cierre
[La prueba o comando end-to-end que demuestra que la feature cumple los requisitos R1..Rn. Sin esto la spec no está completa.]

> Que la suite esté en verde no es esta verificación: acá se ejercita el **camino real**. Al escribirla, dejá dicho:
> - **Contra qué corre.** El motor real (la base, el servicio, el navegador) o un sustituto (SQLite en memoria, mocks). Si el requisito pide el real y solo se puede el sustituto, eso se declara como *diferido*, no como verificado.
> - **Un caso de error.** Al menos un `R<n>` de excepción o regla de negocio central, no solo el camino feliz.
> - **Qué deja atrás.** Los datos de prueba que inserta y cómo se limpian.
