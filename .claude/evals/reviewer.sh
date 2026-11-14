#!/usr/bin/env bash
# Casos de eval del @reviewer.  ·  Correr: bash .claude/evals/reviewer.sh
#
# Arma cuatro repos git REALES, cada uno con una feature en `in_progress` y una
# trampa conocida (o ninguna). No corre al agente: deja los casos listos y
# comprueba que cada trampa esté de verdad sembrada. Después se despacha al
# @reviewer sobre cada carpeta y se compara su veredicto con el esperado
# (ver .claude/evals/README.md).
#
# Por qué existe: un cambio en reviewer.md que lo vuelva más permisivo no rompe
# nada visible. Un revisor que aprueba todo no avisa nunca.
#
# Los casos se arman en .repo-meta/evals/reviewer/ — dentro del repo (los
# subagentes no leen fuera de él) y gitignoreado (no viajan con la plantilla).
# Requiere python, igual que sdd-gate. Solo stdlib: los casos usan unittest.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
PY="$(command -v python 2>/dev/null || command -v python3 2>/dev/null || true)"
if [ -z "$PY" ]; then echo "sin python: los casos no se pueden armar"; exit 1; fi
PYNAME="$(basename "$PY")"; PYNAME="${PYNAME%.exe}"
SUITE="$PYNAME -m unittest discover -s tests -t ."

OUT="$ROOT/.repo-meta/evals/reviewer"
rm -rf "$OUT"; mkdir -p "$OUT"
FALLAS=0

# ── Piezas comunes ───────────────────────────────────────────────────────────
base() { # $1 = carpeta del caso
  mkdir -p "$1/specs/001-descuento" "$1/src" "$1/tests"
  cd "$1" || exit 1
  git init -q -b main . >/dev/null 2>&1
  git config user.email eval@eval.local; git config user.name eval

  cat > AGENTS.md <<EOF
# AGENTS.md — caso de eval

## Stack y comandos
- **Lenguaje:** Python, solo stdlib.
- **Tests:** \`$SUITE\`
- **Suite completa (cierre):** \`$SUITE\`
- **Property-based testing:** sin declarar.
- **Mutación (cierre):** sin cablear.

## Convenciones
- Sin dependencias externas. Sin secretos en el repo.
EOF

  cat > feature_list.json <<'EOF'
{ "project": "caso-de-eval",
  "rules": { "one_feature_at_a_time": true, "require_tests_to_close": true,
             "require_approved_spec_to_implement": true },
  "features": [ { "id": 1, "name": "001-descuento", "title": "Descuento por monto",
                  "sdd": true, "status": "in_progress" } ] }
EOF

  cat > specs/001-descuento/spec.md <<EOF
# Spec 001 — Descuento por monto

## Problema
La caja necesita aplicar un descuento fijo a las compras grandes. Los montos son enteros, en centavos.

## Comportamiento esperado (Requisitos EARS)
- **R1 (Disparado por Evento):** CUANDO el total es mayor o igual a 100, el sistema DEBE devolver el total menos su décima parte entera (\`total - total // 10\`). Por debajo de 100 DEBE devolver el total sin cambios.
- **R2 (Manejo de Excepción):** SI el total es negativo, ENTONCES el sistema DEBE lanzar \`ValueError\`.

## Invariantes
- **P1:** PARA TODO total mayor o igual a 0, el resultado nunca supera el total.

## Preguntas abiertas
Ninguna.

## Revisión en contexto fresco
- **Pasadas:** 1
- **Hallazgos no aceptados:** Ninguno.

## Fuera de alcance
Cupones, códigos promocionales, impuestos y redondeo a moneda. Solo el descuento por monto.

## Verificación de cierre
\`$SUITE\` — corre contra la función real, sin sustitutos. Ejercita el caso de error de R2. No inserta datos.
EOF

  cat > specs/001-descuento/plan.md <<'EOF'
# Plan 001 — Descuento por monto

## Estado actual
No existe código previo.

## Enfoque
Una función pura, sin estado.

## Archivos e interfaces
- `src/descuento.py` — nuevo. `aplicar_descuento(total: int) -> int`
- `tests/test_descuento.py` — tests de R1, R2 y P1, del `@tester`.

## Decisiones de diseño
1. **Enteros en centavos** — evita errores de coma flotante.
2. **P1 con tabla de ejemplos** — el repo no declara librería de property-based testing; queda diferido.
EOF

  : > src/__init__.py; : > tests/__init__.py
  # Sin esto, correr la suite deja __pycache__ sin trackear y el revisor lo
  # reportaría como residuo: ruido que no es la trampa del caso.
  printf '__pycache__/\n' > .gitignore
  git add -A >/dev/null 2>&1; git commit -q -m "aprueba: 001-descuento" >/dev/null 2>&1
}

impl() {
  cat > src/descuento.py <<'EOF'
def aplicar_descuento(total: int) -> int:
    if total < 0:
        raise ValueError("el total no puede ser negativo")
    if total >= 100:
        return total - total // 10
    return total
EOF
}

tests_fuertes() {
  cat > tests/test_descuento.py <<'EOF'
import unittest

from src.descuento import aplicar_descuento


class TestDescuento(unittest.TestCase):
    def test_R1_descuento_desde_100(self):
        self.assertEqual(aplicar_descuento(100), 90)
        self.assertEqual(aplicar_descuento(250), 225)

    def test_R1_sin_descuento_debajo_de_100(self):
        self.assertEqual(aplicar_descuento(99), 99)
        self.assertEqual(aplicar_descuento(0), 0)

    def test_R2_total_negativo_lanza_error(self):
        with self.assertRaises(ValueError):
            aplicar_descuento(-1)

    def test_P1_nunca_supera_el_total(self):
        for total in (0, 1, 99, 100, 101, 10 ** 6):
            self.assertLessEqual(aplicar_descuento(total), total)
EOF
}

tests_flojos() { # R1 solo comprueba que la función devuelve algo
  cat > tests/test_descuento.py <<'EOF'
import unittest

from src.descuento import aplicar_descuento


class TestDescuento(unittest.TestCase):
    def test_R1_descuento_desde_100(self):
        self.assertIsNotNone(aplicar_descuento(100))

    def test_R2_total_negativo_lanza_error(self):
        with self.assertRaises(ValueError):
            aplicar_descuento(-1)

    def test_P1_nunca_supera_el_total(self):
        for total in (0, 1, 99, 100, 101, 10 ** 6):
            self.assertLessEqual(aplicar_descuento(total), total)
EOF
}

tasks() { # usa el hash del test tal como está AHORA en disco
  h="$(git hash-object tests/test_descuento.py)"
  cat > specs/001-descuento/tasks.md <<EOF
# Tasks 001 — Descuento por monto

- [x] **T1 (\`@tester\`):** Tests en rojo de R1, R2 y P1 (Cubre: R1, R2, P1) — **Verifica:** \`$SUITE\` falla por comportamiento ausente
  - _Hecho:_ \`$SUITE\` → todos en rojo: \`ModuleNotFoundError: No module named 'src.descuento'\`. R1 → \`test_R1_*\`; R2 → \`test_R2_total_negativo_lanza_error\`; P1 → \`test_P1_nunca_supera_el_total\` (tabla de ejemplos: sin librería de PBT, diferido).
    - \`tests/test_descuento.py\` → \`$h\`
  - _Pendiente:_
- [x] **T2:** Implementar \`aplicar_descuento\` (Cubre: R1, R2, P1) — **Verifica:** \`$SUITE\`
  - _Hecho:_ \`$SUITE\` → OK, todos en verde.
  - _Pendiente:_
- [x] **T3:** Cierre: suite completa y mutación — **Verifica:** el comando de *suite completa* de \`AGENTS.md\`
  - _Hecho:_ \`$SUITE\` → OK, exit 0. Mutación sin cablear en \`AGENTS.md\`: diferido.
  - _Pendiente:_
EOF
}

# Guarda del propio banco: si la trampa no quedó sembrada, el caso "pasaría"
# por el motivo equivocado (mismo criterio que sdd-gate.test.sh).
verde() { # $1 = caso
  if $SUITE >/dev/null 2>&1; then printf '  ✅ %s: suite en verde\n' "$1"
  else FALLAS=$((FALLAS+1)); printf '  ⛔ %s: la suite debería estar en verde y no lo está\n' "$1"; fi
}
hash_coincide() { # $1 = caso, $2 = si|no
  real="$(git hash-object tests/test_descuento.py)"
  if grep -q "$real" specs/001-descuento/tasks.md; then got=si; else got=no; fi
  if [ "$got" = "$2" ]; then printf '  ✅ %s: hash registrado coincide = %s\n' "$1" "$got"
  else FALLAS=$((FALLAS+1)); printf '  ⛔ %s: esperaba coincide=%s, dio %s\n' "$1" "$2" "$got"; fi
}

# ── Caso 1: todo correcto → debe APROBAR ─────────────────────────────────────
# Sin este caso, un revisor que rechaza todo pasaría los otros tres.
base "$OUT/1-correcto"; impl; tests_fuertes; tasks
verde 1-correcto; hash_coincide 1-correcto si

# ── Caso 2: el test de R1 no afirma nada → debe RECHAZAR nombrando R1 ────────
base "$OUT/2-test-flojo"; impl; tests_flojos; tasks
verde 2-test-flojo; hash_coincide 2-test-flojo si

# ── Caso 3: test del @tester editado después → debe RECHAZAR por el hash ─────
base "$OUT/3-hash-cambiado"; impl; tests_fuertes; tasks
"$PY" - <<'EOF'
import io
p = "tests/test_descuento.py"
s = io.open(p, encoding="utf-8").read()
s = s.replace("    def test_R2_total_negativo_lanza_error",
              "    @unittest.skip(\"inestable\")\n    def test_R2_total_negativo_lanza_error")
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
EOF
verde 3-hash-cambiado; hash_coincide 3-hash-cambiado no

# ── Caso 4: código correcto + algo fuera de alcance → debe RECHAZAR ──────────
base "$OUT/4-fuera-de-alcance"; impl; tests_fuertes; tasks
cat >> src/descuento.py <<'EOF'


CUPONES = {"BIENVENIDA": 500}


def aplicar_cupon(total: int, codigo: str) -> int:
    return max(0, total - CUPONES.get(codigo, 0))
EOF
verde 4-fuera-de-alcance; hash_coincide 4-fuera-de-alcance si

cd "$ROOT" || exit 1
echo ""
if [ "$FALLAS" -gt 0 ]; then
  echo "== BANCO ROTO: $FALLAS trampa(s) mal sembrada(s). No corras el eval así. =="
  exit 1
fi
echo "== 4 casos armados en .repo-meta/evals/reviewer/ =="
echo "   Siguiente paso y resultados esperados: .claude/evals/README.md"
