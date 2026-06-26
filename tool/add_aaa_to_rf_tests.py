#!/usr/bin/env python3
"""Convierte todos los tests a formato Arrange-Act-Assert explícito."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "test" / "sdag_todos_los_rf_test.dart"

FUNC_INPUT_NAMES = {
    "validarTelefono": "telefono",
    "validarDNI": "dni",
    "validarEmail": "email",
    "validarPassword": "password",
    "validarPuntoRecojo": "puntoRecojo",
    "validarCampoRequerido": "campo",
    "validacionCamposIncompletos": "campo",
    "mapRegistroErrorDuplicado": "mensajeDb",
    "mapAuthExceptionError": "tipoError",
    "mapPlacaDuplicadaError": "mensajeDb",
    "mensajeCuentaBloqueada": "cuentaBloqueada",
    "resultadoPagoCulqi": "codigoPago",
    "accionSesionExpirada": "sesionActiva",
    "resultadoSinConexion": "conectado",
    "mensajeConductorNoDisponible": "estadoViaje",
    "reembolsoPosible": "estadoViaje",
    "bajadaPermitida": "estadoAbordaje",
    "pagoReservaCompletado": "pagoExitoso",
    "calcularMontoPago": "cantidadAsientos",
    "asientoPuedeSeleccionarse": "numeroAsiento",
    "puedeEscanearQR": "valorQr",
    "validarPorcentajeComision": "porcentaje",
    "conductorElegibleParaListado": "conductor",
}


def split_args(args_str: str) -> list[str]:
    parts: list[str] = []
    current: list[str] = []
    depth = 0
    in_str = False
    quote = ""
    for ch in args_str:
        if in_str:
            current.append(ch)
            if ch == quote:
                in_str = False
            continue
        if ch in "'\"":
            in_str = True
            quote = ch
            current.append(ch)
            continue
        if ch == "(":
            depth += 1
            current.append(ch)
            continue
        if ch == ")":
            depth -= 1
            current.append(ch)
            continue
        if ch == "," and depth == 0:
            parts.append("".join(current).strip())
            current = []
            continue
        current.append(ch)
    tail = "".join(current).strip()
    if tail:
        parts.append(tail)
    return parts


def parse_call(expr: str) -> tuple[str, str] | None:
    expr = expr.strip()
    m = re.match(r"^(\w+)\((.*)\)$", expr, re.DOTALL)
    if not m:
        return None
    return m.group(1), m.group(2)


def literal_to_const(value: str, base: str, idx: int) -> tuple[str, str]:
    value = value.strip()
    if value == "null":
        return f"campoVacio{idx}", "null"
    if value in ("true", "false"):
        return f"{base}Flag{idx}", value
    if re.match(r"^-?\d+(\.\d+)?$", value):
        return f"{base}Valor{idx}", value
    if value.startswith("'") or value.startswith('"'):
        inner = value[1:-1]
        safe = re.sub(r"[^a-zA-Z0-9]", "", inner)[:20] or f"valor{idx}"
        return f"{base}{safe.capitalize()}{idx}", value
    if value.startswith("{") or value.startswith("<"):
        return f"{base}Set{idx}", value
    return f"{base}Arg{idx}", value


def transform_property_act(expr: str, idx: int) -> tuple[list[str], str, str]:
    m = re.match(r"^(\w+)\.(\w+)$", expr.strip())
    if not m:
        return [], expr, f"resultado{idx}"
    obj, prop = m.group(1), m.group(2)
    var = f"{prop}{idx}"
    act = f"final {var} = {obj}.{prop};"
    return [], act, var


def transform_call_act(expr: str, idx: int) -> tuple[list[str], str, str]:
    parsed = parse_call(expr)
    if not parsed:
        prop = transform_property_act(expr, idx)
        if prop[1] != expr:
            return prop
        return [], f"final resultado{idx} = {expr};", f"resultado{idx}"

    func, args_str = parsed
    base = FUNC_INPUT_NAMES.get(func, "entrada")

    if not args_str.strip():
        var = f"resultado{idx}"
        return [], f"final {var} = {func}();", var

    if func == "conductorElegibleParaListado":
        arrange = [
            "const cuentaActiva = true;",
            "const estadoConductor = 'activo';",
        ]
        act = f"final resultado{idx} = {func}(cuentaActiva: cuentaActiva, estado: estadoConductor);"
        return arrange, act, f"resultado{idx}"

    if func == "asientoPuedeSeleccionarse":
        args = split_args(args_str)
        if len(args) == 2:
            num = args[0].strip()
            var = f"resultado{idx}"
            act = f"final {var} = {func}({num}, ocupados);"
            return [], act, var

    if func == "resultadoPagoCulqi":
        args = split_args(args_str)
        if len(args) == 2:
            arrange = [
                f"const codigoHttp{idx} = {args[0].strip()};",
                f"const mensajePago{idx} = {args[1].strip()};",
            ]
            var = f"resultado{idx}"
            act = f"final {var} = {func}(codigoHttp{idx}, mensajePago{idx});"
            return arrange, act, var

    args = split_args(args_str)
    arrange: list[str] = []
    call_args: list[str] = []
    for j, arg in enumerate(args):
        name, const_val = literal_to_const(arg, base, idx * 10 + j)
        if name.startswith("conductor") or "Set" in name:
            arrange.append(f"final {name} = {const_val};")
        else:
            arrange.append(f"const {name} = {const_val};")
        call_args.append(name)

    var = f"resultado{idx}"
    act = f"final {var} = {func}({', '.join(call_args)});"
    return arrange, act, var


def transform_test_body(body: str) -> str:
    lines = body.split("\n")
    pre_arrange: list[str] = []
    expects: list[tuple[str, str]] = []
    print_line = "      print('');"

    for raw in lines:
        line = raw.rstrip()
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("print("):
            print_line = line
            continue
        if stripped.startswith("// Flujo exitoso"):
            pre_arrange.append(f"      // Arrange — {stripped[2:].strip()}")
            continue
        if stripped.startswith("final ") and "=" in stripped:
            pre_arrange.append(f"      {stripped}")
            continue
        m = re.match(r"(\s*)expect\((.+),\s*(.+)\);", line)
        if m:
            expects.append((m.group(2).strip(), m.group(3).strip()))
            continue

    all_arrange: list[str] = list(pre_arrange)
    act_lines: list[str] = []
    assert_lines: list[str] = []

    if not all_arrange:
        all_arrange.append("      // Arrange — datos de entrada del caso de prueba")

    for i, (act_expr, matcher) in enumerate(expects):
        extra_arrange, act, result_var = transform_call_act(act_expr, i + 1)
        for a in extra_arrange:
            decl = f"      {a}"
            if decl not in all_arrange:
                all_arrange.append(decl)
        act_lines.append(f"      {act}")
        assert_lines.append(f"      expect({result_var}, {matcher});")

    # Normalizar encabezado Arrange único
    normalized_arrange: list[str] = []
    has_header = any("// Arrange" in l for l in all_arrange)
    if not has_header:
        normalized_arrange.append("      // Arrange — datos de entrada del caso de prueba")
    for l in all_arrange:
        if l.strip().startswith("// Arrange —") and normalized_arrange:
            if not any(x.strip().startswith("// Arrange —") for x in normalized_arrange):
                normalized_arrange.append(l)
            else:
                normalized_arrange.append(l.replace("// Arrange —", "//").replace("      //", "      // Contexto —", 1))
        else:
            normalized_arrange.append(l)

    if normalized_arrange and not normalized_arrange[0].strip().startswith("// Arrange"):
        normalized_arrange.insert(0, "      // Arrange — datos de entrada del caso de prueba")

    out = []
    out.extend(normalized_arrange)
    out.append("      // Act — ejecutar la validación / regla de la app")
    out.extend(act_lines)
    out.append("      // Assert — verificar el resultado esperado del CP")
    out.extend(assert_lines)
    out.append(print_line)
    return "\n".join(out)


def transform_file(content: str) -> str:
    pattern = re.compile(
        r"(    test\('([^']+)',\s*\(\)\s*\{)\n(.*?)(    \}\);)",
        re.DOTALL,
    )

    def repl(m: re.Match) -> str:
        header, _title, body, closing = m.group(1), m.group(2), m.group(3), m.group(4)
        new_body = transform_test_body(body)
        return f"{header}\n{new_body}\n{closing}"

    return pattern.sub(repl, content)


def main() -> None:
    content = SRC.read_text(encoding="utf-8")
    transformed = transform_file(content)
    SRC.write_text(transformed, encoding="utf-8")
    count = len(re.findall(r"// Assert — verificar", transformed))
    print(f"Transformados {count} tests en {SRC}")


if __name__ == "__main__":
    main()
