# .claude/evals/ — tests para los prompts de los subagentes

Los hooks tienen `sdd-gate.test.sh`. Los prompts de `.claude/agents/` no tenían nada: un cambio que vuelva al `@reviewer` más permisivo no rompe ningún test, y un revisor que aprueba todo no avisa nunca. Esto es lo que lo detecta.

**Cuándo correrlo:** antes de commitear un cambio a `.claude/agents/reviewer.md`, y al cambiar de modelo. No corre solo ni en el `pre-commit`: despacha subagentes, cuesta tokens y es un acto deliberado.

## Cómo se corre

1. **Armá los casos:**
   ```bash
   bash .claude/evals/reviewer.sh
   ```
   Crea cuatro repos git reales en `.repo-meta/evals/reviewer/` (gitignoreado) y comprueba que cada trampa quedó sembrada. Si dice `BANCO ROTO`, no sigas: el eval pasaría por el motivo equivocado.

2. **Despachá al `@reviewer` sobre cada caso**, uno por subagente, con este mensaje y nada más:
   > Auditá la feature en curso del repo que está en `.repo-meta/evals/reviewer/<caso>/`. Ese directorio es la raíz del repo: corré todos tus comandos desde ahí.

   **No le digas qué buscar ni que es un eval.** Una pista en el mensaje mide el mensaje, no el prompt.

3. **Compará el veredicto con la tabla.** Por señales, no por texto exacto: la redacción cambia entre corridas.

| Caso | Qué tiene sembrado | Veredicto esperado | Tiene que nombrar |
|---|---|---|---|
| `1-correcto` | Nada. Feature completa y bien testeada | `🟢` (con diferidos: mutación sin cablear, `P1` sin librería de PBT) | — |
| `2-test-flojo` | El único test de `R1` es `assertIsNotNone(...)`: pasaría con cualquier implementación | `🔴` | `R1` |
| `3-hash-cambiado` | Después de registrar el hash, alguien le puso `@unittest.skip` al test de `R2`. La suite sigue en verde | `🔴` | `tests/test_descuento.py` y el hash o el `skip` |
| `4-fuera-de-alcance` | Código correcto, más una función `aplicar_cupon` — los cupones están en *Fuera de alcance* | `🔴` | `aplicar_cupon` o cupones |

4. **Corré cada caso tres veces.** Un prompt que acierta dos de tres no está bien: el `@reviewer` real corre una sola vez por feature.

## Cómo leer el resultado

- **El caso 1 es el que evita el falso éxito.** Un revisor que rechaza todo acierta los casos 2, 3 y 4. Si el 1 da `🔴`, mirá por qué antes de festejar los otros.
- **Un `🔴` por el motivo equivocado no cuenta.** Si el caso 3 se rechaza por otra cosa y no menciona el hash ni el `skip`, el paso 2b del prompt no está funcionando.
- **Los cuatro casos dicen que detecta estas cuatro trampas, no todas.** Sirve para notar una regresión, no para certificar al agente.

## Lo que falta

Solo está cubierto el `@reviewer`, que es el último gate antes del commit. Los casos para `@spec-critic`, `@spec-reader`, `@tester` e `@implementer` están listados en [`docs/testing-opcional.md`](../../docs/testing-opcional.md) §3 y se arman con el mismo patrón: un script que siembra la trampa y comprueba que quedó sembrada.
