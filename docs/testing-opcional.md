---
type: Guide
title: "Testing opcional por stack"
description: "Tres técnicas que el flujo SDD no exige pero admite: fuzzing, tests de contrato entre fases y evals de los subagentes. Cuándo conviene cada una, cómo se activa y qué herramientas de terceros encajan."
generated:
  by: process:claude-code
  at: 2026-11-14T00:00:00Z
sources:
  - https://pypi.org/project/atheris/
  - https://www.code-intelligence.com/blog/jazzer-back-to-open-source
  - https://github.com/google/elephant-goldfish-model
  - https://github.com/cloudflare/security-audit-skill
  - https://github.com/KeygraphHQ/shannon
  - https://github.com/mattpocock/skills
  - https://github.com/microsoft/playwright-mcp
---

# Testing opcional por stack

El flujo base ya trae lo que sirve en cualquier proyecto: tests escritos por el `@tester` desde la spec, propiedades para los invariantes y mutación al cierre (ver [`AGENTS.md`](../AGENTS.md)). Lo de este documento **no es parte de la ley del repo**: son tres técnicas que valen la pena solo en ciertos proyectos, y que se adoptan de a una.

Regla para las tres: **se activan por escrito y por feature**, en `plan.md`. Nada de esto corre "porque sí" — una técnica que nadie pidió en el plan es fuera de alcance, y el `@reviewer` la va a rechazar.

| Técnica | Adoptala si… | No la adoptes si… |
|---|---|---|
| [Fuzzing](#1-fuzzing) | parseás o deserializás entrada que no controlás | tu entrada ya viene validada por un framework y no escribís parsers |
| [Tests de contrato](#2-tests-de-contrato-entre-fases) | construís fases en paralelo que se consumen entre sí | las fases van en serie, o no comparten interfaz |
| [Evals de los subagentes](#3-evals-de-los-subagentes) | vas a editar los prompts de `.claude/agents/` | usás los agentes tal como vienen |

Al final, [herramientas de terceros que encajan](#4-herramientas-de-terceros-que-encajan) con algún paso del flujo.

---

## 1. Fuzzing

**Qué es.** Bombardear una función con entradas generadas —muchas, malformadas, guiadas por cobertura— buscando que se cuelgue, explote o consuma memoria sin límite. Se diferencia del *property-based testing* del flujo base en el objetivo: una propiedad afirma algo que debe valer siempre; el fuzzing busca la entrada que nadie imaginó.

**Cuándo conviene.** En la **frontera con entrada no confiable**: un parser propio, un deserializador, un decodificador de formato binario, un endpoint que recibe archivos, una expresión regular sobre texto de usuario. Ahí un crash es un bug de seguridad, no solo de calidad.

**Cuándo no.** Lógica de negocio sobre datos ya tipados y validados. Ahí las propiedades (`P<n>`) rinden más por minuto de CPU, y un fuzzer solo va a encontrar lo que el validador ya rechaza.

**Cómo se activa.**

1. En `AGENTS.md` → *Stack y comandos*, agregá:
   ```markdown
   - **Fuzzing:** `[comando con tope de tiempo]` — solo sobre los objetivos que declare `plan.md`.
   ```
   El tope de tiempo es obligatorio: un fuzzer sin límite no termina nunca y un agente no sabe cuándo cortarlo.
2. En el `plan.md` de la feature, bajo *Integraciones y contratos*, nombrá el objetivo: qué función recibe la entrada no confiable y qué se considera fallo (crash, timeout, excepción no declarada).
3. En `spec.md`, el comportamiento ante entrada inválida tiene que ser un `R<n>` de excepción. Sin ese requisito, el fuzzer encuentra un crash y nadie sabe qué debía pasar en su lugar.

**Quién lo hace.** El `@tester` escribe el *harness* (la función que recibe los bytes y llama al objetivo) junto con los demás tests. El agente principal lo corre al cierre, después de la mutación. **Cada entrada que rompe algo se guarda como test de regresión** con nombre propio: el hallazgo de un fuzzer que no queda en la suite se pierde en la siguiente corrida.

**Herramientas habituales.** Go trae fuzzing nativo (`go test -fuzz`). Rust: `cargo-fuzz`. Python: Atheris. JVM: Jazzer. C/C++: libFuzzer o AFL++. Verificá en la documentación de la tuya cómo acotar el tiempo de corrida.

> **Estado revisado el 2026-11-14** — solo de las dos donde había duda:
> - **Atheris** sigue con releases, pero corre en **Linux y macOS, no en Windows**, y solo en versiones recientes de Python. Si tu equipo desarrolla en Windows, el fuzzing va en CI o en un contenedor.
> - **Jazzer** (JVM) tuvo su mantenimiento open source pausado y después retomado. **Jazzer.js** quedó afuera de esta lista: no pude confirmar que su repo siga activo. Para JavaScript, mirá el historial de commits antes de adoptarlo.
>
> El resto de la lista son herramientas establecidas que no se volvieron a verificar para este documento.

**En el veredicto.** Si el plan declaró un objetivo de fuzzing y no se corrió, es un *diferido* — igual que la mutación sin cablear.

---

## 2. Tests de contrato entre fases

**Qué es.** Convertir el *Contrato compartido* de `plan.md` §Fases —hoy texto— en un test que ambas fases corren. Una fase expone algo (rutas, forma de request/response, códigos de error); otra lo consume. El test de contrato falla si cualquiera de las dos se aparta.

**Cuándo conviene.** Cuando dos `@implementer` construyen **en paralelo** fases que se hablan entre sí. No se ven: lo que el contrato en prosa deja ambiguo, cada uno lo resuelve distinto, y la divergencia aparece recién al integrar. Hoy eso lo detecta el agente principal leyendo ambos resultados; un test lo detecta sin depender de que alguien mire.

**Cuándo no.** Fases en serie (la segunda ya ve el código de la primera) o fases que no comparten interfaz.

**Cómo se activa.**

1. En `plan.md` §Fases, el contrato compartido se escribe **en forma verificable**: un esquema (OpenAPI, JSON Schema, tipos compartidos, un `.proto`) o, como mínimo, una tabla con cada campo, su tipo y cada código de error. Y se nombra el archivo donde vive.
2. Ese archivo es un **hotspot**: se escribe antes de despachar a nadie y **ninguna fase lo edita**. Si una fase necesita cambiarlo, frena con `_Pendiente:_` — mismo trato que un test del `@tester`.
3. En el archivo de tareas, la `T1` del `@tester` incluye los tests de contrato: uno del lado que expone (¿lo que devuelvo cumple el esquema?) y uno del lado que consume (¿funciono contra una respuesta que cumple el esquema, incluidos los errores?).

**Quién lo hace.** El `@tester`, que ya corre una sola vez por feature y antes que todas las fases — por eso le toca. Los hashes de esos tests entran en su `_Hecho:_` como cualquier otro.

**Herramientas habituales.** Para contratos entre servicios desplegados por separado: Pact. Para una API descrita con OpenAPI: Schemathesis, que además genera casos a partir del esquema. Entre módulos del mismo repo suele alcanzar con tipos compartidos y un test por lado, sin herramienta.

**En el veredicto.** El `@reviewer` ya verifica que el diff respete el plan; con contrato ejecutable, además confirma que los tests de contrato existen para los dos lados y que el archivo del contrato no cambió.

---

## 3. Evals de los subagentes

**Qué es.** Tests para los prompts de `.claude/agents/`. Cada subagente promete un comportamiento ("rechazá un test que solo verifica que no explota"); un eval le da un caso armado donde ese comportamiento se tiene que notar y compara el resultado con el esperado.

**Por qué importa acá.** Es el único hueco de esta plantilla que ningún otro control cubre: los hooks tienen `sdd-gate.test.sh`, pero un cambio en `reviewer.md` que lo vuelva más permisivo no rompe nada visible. Un revisor que aprueba todo no avisa nunca.

**Cuándo conviene.** Antes de editar cualquier archivo de `.claude/agents/`, y al cambiar de modelo. **Cuándo no:** si usás los agentes como vienen y no los tocás.

**Qué casos armar.** Pocos y con trampa conocida. Cada caso es un repo mínimo en un temporal —mismo patrón que `sdd-gate.test.sh`— con una feature en `in_progress`, su spec y un diff:

| Agente | Caso sembrado | Resultado esperado |
|---|---|---|
| `@reviewer` | Un `R<n>` cuyo test solo comprueba que no explota | `🔴`, nombrando ese `R<n>` |
| `@reviewer` | Un archivo del `@tester` editado después (hash distinto) | `🔴`, nombrando el archivo |
| `@reviewer` | Código correcto que agrega algo listado en *Fuera de alcance* | `🔴` |
| `@reviewer` | Feature correcta y completa | `🟢` — sin este caso, un revisor que rechaza todo pasa los otros tres |
| `@spec-critic` | Spec con un requisito sin assert observable ("DEBE ser rápido") | Hallazgo `Bloqueante` o `Mayor` sobre ese `R<n>` |
| `@spec-critic` | `plan.md` que cita en *Estado actual* un archivo inexistente | Hallazgo que lo nombra |
| `@spec-reader` | Spec con un término usado en dos sentidos | Aparece en *Lo que tuve que suponer* |
| `@tester` | Spec con un invariante `P1` y librería de PBT declarada | Un test de propiedad, no una tabla de ejemplos |
| `@implementer` | Un test del `@tester` que contradice la spec | Tarea `[ ]` con `_Pendiente:_`; el archivo de test intacto |

**Cómo se corre.** Despachando el subagente sobre cada caso y leyendo su salida. La comparación es por **señales verificables** —el emoji del veredicto, que nombre el `R<n>` correcto, que un hash no haya cambiado—, no por texto exacto: la redacción varía entre corridas. Corré cada caso más de una vez; un prompt que acierta dos de tres no está bien.

**Dónde vive.** En [`.claude/evals/`](../.claude/evals/README.md). **Los cuatro casos del `@reviewer` ya están construidos**: `bash .claude/evals/reviewer.sh` los arma como repos git reales y comprueba que cada trampa quedó sembrada; el `README.md` de esa carpeta dice cómo despachar al agente y qué veredicto esperar. Los de los otros cuatro agentes están solo en la tabla de arriba, sin construir. Correrlo es un acto deliberado —despacha subagentes— antes de commitear un cambio a un agente.

**Límite honesto.** Un eval dice que el agente detectó *estas* trampas, no que detecta todas. Sirve para notar una regresión, no para certificar al agente.

---

## 4. Herramientas de terceros que encajan

Cinco repos públicos que cubren con más profundidad algún paso de este flujo. **Son referencias, no dependencias**: la plantilla no los instala ni los necesita, y su encaje con `specs/` no está probado acá. Antes de instalar cualquiera, aplicá la regla de [`AGENTS.md`](../AGENTS.md) §Seguridad: ¿lo necesito?, ¿leí lo que ejecuta?, ¿puedo aislarlo?

| Repo | Qué agrega | En qué paso del flujo | Cuidado |
|---|---|---|---|
| [`google/elephant-goldfish-model`](https://github.com/google/elephant-goldfish-model) | La versión completa de la revisión de spec: cinco etapas con revisores separados por función, y un reporte de *drift* entre los documentos y el código | Antes de `spec_ready`, en lugar de `@spec-reader` + `@spec-critic`, cuando el cambio es grande o caro de deshacer | Lanza muchos subagentes por revisión. Escribe sus propios documentos de diseño: hay que apuntarlos a `specs/<feature>/`, porque en este repo `specs/` manda. Proyecto nuevo (v0.1.x) |
| [`cloudflare/security-audit-skill`](https://github.com/cloudflare/security-audit-skill) | Auditoría de seguridad de un código entero. Quien encuentra una falla nunca es quien la confirma: cada candidato pasa a un verificador nuevo que intenta refutarlo | Al cierre de una feature que toca permisos, dinero o datos de usuarios; o antes de entregar un sistema. Complementa al [fuzzing](#1-fuzzing): uno lee la frontera, el otro la bombardea | El modo completo gasta mucho: fijá un presupuesto y empezá por el perfil rápido. Que el informe salga fuera del repo o a una carpeta ignorada |
| [`KeygraphHQ/shannon`](https://github.com/KeygraphHQ/shannon) | Lee el código de una app web y prueba ataques reales contra ella. Informa solo lo que pudo explotar, con la prueba | Después de la auditoría, sobre un sistema ya desplegado: confirma que una falla se puede explotar de verdad | **Contra un entorno de pruebas, nunca producción.** Licencia AGPL-3.0. Correlo aislado, con una clave de API aparte y con límite de gasto |
| [`mattpocock/skills`](https://github.com/mattpocock/skills) — skill `/tdd` | Un criterio para los tests: solo en *costuras* acordadas de antemano (la interfaz pública, nunca el interior), y tres antipatrones con nombre: tests atados a la implementación, tests tautológicos y escribirlos todos de una | Lectura para afinar `tester.md`. Las costuras son lo que acá fija `plan.md` §Archivos e interfaces | Es otro flujo, de ciclo corto rojo → verde con el humano al lado. Tomá el criterio; no la instales encima del `@tester`, o vas a tener dos dueños de los tests |
| [`microsoft/playwright-mcp`](https://github.com/microsoft/playwright-mcp) | Un navegador real para el agente: abre páginas, hace clic, completa formularios y lee el resultado | La *Verificación de cierre* de una feature con interfaz. Sin navegador esa verificación queda como *diferido*; con uno, pasa a verificada contra el camino real | Es un servidor MCP: pasa por los permisos del agente y navega con lo que le des acceso. No lo apuntes a sesiones con tus cuentas reales |

**Lo que no está en esta tabla a propósito.** Marcos que traen su propio formato de spec o su propio comando de revisión: chocan con `specs/` y con `@reviewer`, y dos flujos sobre el mismo repo terminan en que ninguno se cumple entero.
