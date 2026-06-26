#!/usr/bin/env python3
"""Genera test/sdag_tdd_momento3_test.dart con formato Momento 3 TDD (UTP)."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "test" / "sdag_todos_los_rf_test.dart"
OUT = ROOT / "test" / "sdag_tdd_momento3_test.dart"


def cp_id(title: str) -> str:
    m = re.match(r"(CP\d+)", title)
    return m.group(1) if m else "CP??"


def escenario_sin_cp(title: str) -> str:
    return re.sub(r"^CP\d+\s*—\s*", "", title).strip()


def precondicion(group: str, title: str, arrange_code: list[str]) -> str:
    esc = escenario_sin_cp(title).lower()
    rf = group.split("—", 1)[-1].strip() if "—" in group else group
    if "flujo exitoso" in esc:
        return f"El sistema SDAG está listo y el actor puede ejecutar «{rf}» con datos válidos."
    if "correo ya registrado" in esc or "correo duplicado" in esc:
        return "Existe un intento de registro/edición con un correo que ya está en la base de datos."
    if "teléfono inválido" in esc:
        return "El formulario recibe un número de teléfono peruano con formato incorrecto."
    if "dni inválido" in esc:
        return "Se ingresa un DNI que no cumple la regla de 8 dígitos."
    if "campo vacío" in esc:
        return "El actor intenta guardar o continuar sin completar el campo obligatorio."
    if "campos requeridos incompletos" in esc or "campos vacíos" in esc:
        return "Hay al menos un campo obligatorio vacío o nulo en el formulario."
    if "formato de datos inválido" in esc:
        return "Los datos ingresados no cumplen el formato definido por las validaciones de la app."
    if "credenciales incorrectas" in esc:
        return "El actor intenta iniciar sesión con credenciales que no coinciden."
    if "cuenta bloqueada" in esc:
        return "La cuenta del usuario está marcada como suspendida/bloqueada."
    if "pago rechazado" in esc or "pago fallido" in esc:
        return "La pasarela de pago responde con un código de error o el pago no se completa."
    if "sin conductores" in esc:
        return "No hay conductores activos disponibles para la consulta o búsqueda."
    if "sin conexión" in esc:
        return "El dispositivo no tiene conexión de red en el momento de la consulta."
    if "qr" in esc and ("inválido" in esc or "escaneado" in esc or "vencido" in esc):
        return "El código QR escaneado o presentado no es válido o ya fue utilizado."
    if "reembolso" in esc and "salió" in esc:
        return "El vehículo ya no está en estado «esperando» (ya inició el viaje)."
    if "porcentaje fuera de rango" in esc:
        return "El administrador intenta configurar un porcentaje de comisión fuera de 0–100."
    if "lista vacía" in esc or "sin " in esc:
        return f"Escenario alterno del RF: {escenario_sin_cp(title)}."
    if arrange_code:
        return f"Estado inicial preparado para validar «{escenario_sin_cp(title)}» en {rf}."
    return f"Precondición del escenario «{escenario_sin_cp(title)}» para {rf}."


def accion(group: str, title: str, act_lines: list[str]) -> str:
    esc = escenario_sin_cp(title).lower()
    if act_lines:
        calls = []
        for line in act_lines:
            m = re.search(r"=\s*(\w+)\(", line)
            if m:
                calls.append(m.group(1))
        if calls:
            funcs = ", ".join(dict.fromkeys(calls))
            return f"Se ejecuta la lógica de negocio/validación de la app: {funcs}()."
    if "flujo exitoso" in esc:
        return "El actor completa la operación con entradas válidas y el sistema procesa la regla."
    if "consultar" in esc or "ver " in esc:
        return "El actor solicita la información o vista correspondiente al requerimiento."
    return f"Se dispara la acción del caso: {escenario_sin_cp(title)}."


def resultado_esperado(expect_lines: list[str]) -> str:
    parts = []
    for line in expect_lines:
        m = re.search(r"expect\([^,]+,\s*(.+)\);", line)
        if m:
            parts.append(m.group(1).strip())
    if parts:
        return "El sistema debe responder: " + "; ".join(parts) + "."
    return "El sistema debe comportarse según la regla definida para este escenario."


def transform_test_body(body: str, group: str, title: str) -> str:
    lines = body.split("\n")
    arrange_code: list[str] = []
    act_code: list[str] = []
    expect_lines: list[str] = []
    print_line = ""

    for raw in lines:
        line = raw.rstrip()
        s = line.strip()
        if not s:
            continue
        if s.startswith("print("):
            print_line = line
            continue
        if s.startswith("// Arrange"):
            continue
        if s.startswith("// Act"):
            continue
        if s.startswith("// Assert"):
            continue
        if s.startswith("const ") or s.startswith("final "):
            if "resultado" not in s or "=" in s and "resultado" in s and s.startswith("final resultado"):
                if s.startswith("const ") or (s.startswith("final ") and "lista" in s or "ocupados" in s):
                    arrange_code.append(line)
            elif s.startswith("final resultado"):
                act_code.append(line)
            else:
                arrange_code.append(line)
        elif s.startswith("expect("):
            expect_lines.append(line)
        elif s.startswith("final resultado"):
            act_code.append(line)

    # Re-parse more reliably: anything before first act resultado is arrange
    arrange_code = []
    act_code = []
    expect_lines = []
    print_line = ""
    phase = "arrange"
    for raw in lines:
        line = raw.rstrip()
        s = line.strip()
        if not s:
            continue
        if s.startswith("print("):
            print_line = line
            continue
        if s.startswith("// Arrange") or s.startswith("// Act") or s.startswith("// Assert"):
            if s.startswith("// Act"):
                phase = "act"
            elif s.startswith("// Assert"):
                phase = "assert"
            continue
        if s.startswith("expect("):
            expect_lines.append(line)
            phase = "assert"
            continue
        if phase == "arrange" and (s.startswith("const ") or (s.startswith("final ") and "resultado" not in s)):
            arrange_code.append(line)
        elif s.startswith("final resultado") or (phase == "act" and s.startswith("final ")):
            act_code.append(line)
            phase = "act"

    pre = precondicion(group, title, arrange_code)
    act = accion(group, title, act_code)
    res = resultado_esperado(expect_lines)

    out = []
    out.append(f"      // PRECONDICIÓN: {pre}")
    for l in arrange_code:
        out.append(f"      {l.strip()}" if not l.startswith("      ") else l)
    out.append(f"      // ACCIÓN: {act}")
    for l in act_code:
        out.append(f"      {l.strip()}" if not l.startswith("      ") else l)
    out.append(f"      // RESULTADO ESPERADO: {res}")
    for l in expect_lines:
        out.append(f"      {l.strip()}" if not l.startswith("      ") else l)
    out.append("      // RESULTADO OBTENIDO: se completa al correr el test")
    out.append(print_line)
    return "\n".join(out)


def transform_file(content: str) -> str:
    header = """import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/core/validators/sdag_validators.dart';

// ================================================================
// SDAG — Semana 13 UTP — Momento 3 TDD (Pruebas de Software)
// 126 Requerimientos Funcionales × Casos de Prueba ejecutables
// Momento 1: escenarios «¿qué pasa si…?» | Momento 2: ficha | Momento 3: test
// Ciclo TDD: Rojo (falla) → Verde (pasa) → Refactorizar
// Ejecutar: flutter test test/sdag_tdd_momento3_test.dart --reporter expanded
// ================================================================

"""

    group_pat = re.compile(
        r"group\('(?P<group>[^']+)',\s*\(\)\s*\{(?P<body>.*?)\n  \}\);",
        re.DOTALL,
    )
    test_pat = re.compile(
        r"    test\('(?P<title>[^']+)',\s*\(\)\s*\{(?P<body>.*?)\n    \}\);",
        re.DOTALL,
    )

    def transform_group(m: re.Match) -> str:
        group = m.group("group")
        body = m.group("body")

        def transform_test(tm: re.Match) -> str:
            title = tm.group("title")
            tb = transform_test_body(tm.group("body"), group, title)
            return f"    test('{title}', () {{\n{tb}\n    }});"

        new_body = test_pat.sub(transform_test, body)
        return f"  group('{group}', () {{\n{new_body}\n  }});"

    # Replace void testRFxxx functions with inline groups in main OR keep structure
    # Keep same void testRF structure from source
    result = content
    # Update file header comment block
    result = re.sub(
        r"import 'package:flutter_test/flutter_test.dart';\nimport 'package:sdag/core/validators/sdag_validators.dart';\n\n// =+\n// SDAG — Suite Completa.*?\n// =+\n\n",
        header,
        result,
        count=1,
        flags=re.DOTALL,
    )

    # Transform each group inside void functions
    def repl_group(m: re.Match) -> str:
        return transform_group(m)

    result = group_pat.sub(repl_group, result)

    # Update main banner
    result = result.replace(
        "  print('  SDAG — Suite Completa de Tests Flutter');",
        "  print('  SDAG — Momento 3 TDD — Pruebas de Software UTP');",
    )
    return result


def main() -> None:
    content = SRC.read_text(encoding="utf-8")
    out = transform_file(content)
    OUT.write_text(out, encoding="utf-8")
    tests = len(re.findall(r"// PRECONDICIÓN:", out))
    print(f"Generado {OUT} con {tests} tests")


if __name__ == "__main__":
    main()
