#!/usr/bin/env python3
"""Reescribe sdag_todos_los_rf_test.dart para usar sdag_validators.dart."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "test" / "sdag_todos_los_rf_test.dart"
OUT = SRC

content = SRC.read_text(encoding="utf-8")

# Import
if "sdag_validators.dart" not in content:
    content = content.replace(
        "import 'package:flutter_test/flutter_test.dart';",
        "import 'package:flutter_test/flutter_test.dart';\nimport 'package:sdag/core/validators/sdag_validators.dart';",
    )

# ── Bloques multilínea ──────────────────────────────────────────────────────

PHONE_BLOCK = re.compile(
    r"      String\? val\(String\? v\) \{\n"
    r"        if \(v == null \|\| v\.trim\(\)\.isEmpty\) return 'Campo requerido';\n"
    r"        if \(!RegExp\(r'\^\\d\{9\}\$'\)\.hasMatch\(v\.trim\(\)\)\) return 'Teléfono inválido';\n"
    r"        return null;\n"
    r"      \}\n"
    r"      expect\(val\('12345'\), equals\('Teléfono inválido'\)\);\n"
    r"      expect\(val\('987654321'\), isNull\);",
    re.MULTILINE,
)
content = PHONE_BLOCK.sub(
    "      expect(validarTelefono('12345'), equals('Teléfono inválido'));\n"
    "      expect(validarTelefono('987654321'), isNull);",
    content,
)

DNI_BLOCK = re.compile(
    r"      String\? val\(String\? v\) \{\n"
    r"        if \(v == null \|\| v\.trim\(\)\.isEmpty\) return 'Campo requerido';\n"
    r"        if \(!RegExp\(r'\^\\d\{8\}\$'\)\.hasMatch\(v\.trim\(\)\)\) return 'DNI inválido';\n"
    r"        return null;\n"
    r"      \}\n"
    r"      expect\(val\('1234'\), equals\('DNI inválido'\)\);\n"
    r"      expect\(val\('12345678'\), isNull\);",
    re.MULTILINE,
)
content = DNI_BLOCK.sub(
    "      expect(validarDNI('1234'), equals('DNI inválido'));\n"
    "      expect(validarDNI('12345678'), isNull);",
    content,
)

UUID_BLOCK = re.compile(
    r"      bool esUUID\(String s\) \{\n"
    r"        final p = s\.contains\('\|'\) \? s\.split\('\|'\)\[0\] : s;\n"
    r"        return RegExp\(r'\^\[0-9a-f\]\{8\}-\[0-9a-f\]\{4\}-\[0-9a-f\]\{4\}-\[0-9a-f\]\{4\}-\[0-9a-f\]\{12\}\$', caseSensitive: false\)\.hasMatch\(p\.trim\(\)\);\n"
    r"      \}\n"
    r"      expect\(esUUID\('no-es-uuid'\), isFalse\);\n"
    r"      expect\(esUUID\('9b4020ff-4a93-48e4-9931-b861b5dfa482\|1'\), isTrue\);",
    re.MULTILINE,
)
content = UUID_BLOCK.sub(
    "      expect(puedeEscanearQR('no-es-uuid'), isFalse);\n"
    "      expect(puedeEscanearQR('9b4020ff-4a93-48e4-9931-b861b5dfa482|1'), isTrue);",
    content,
)

# ── Reemplazos de una línea ─────────────────────────────────────────────────

SINGLE = [
    (
        "      String mapErr(String m) => m.toLowerCase().contains('already') ? 'EmailDuplicadoFailure' : 'GenericFailure';\n"
        "      expect(mapErr('email already registered'), equals('EmailDuplicadoFailure'));",
        "      expect(mapRegistroErrorDuplicado('email already registered'), equals('EmailDuplicadoFailure'));",
    ),
    (
        "      String mapErr(String t) => t == 'AuthException' ? 'InvalidCredentialsFailure' : 'GenericFailure';\n"
        "      expect(mapErr('AuthException'), equals('InvalidCredentialsFailure'));",
        "      expect(mapAuthExceptionError('AuthException'), equals('InvalidCredentialsFailure'));",
    ),
    (
        "      String mapErr(String m) => (m.toLowerCase().contains('placa') || m.toLowerCase().contains('plate')) ? 'PlacaDuplicadaFailure' : 'GenericFailure';\n"
        "      expect(mapErr('plate already assigned'), equals('PlacaDuplicadaFailure'));",
        "      expect(mapPlacaDuplicadaError('plate already assigned'), equals('PlacaDuplicadaFailure'));",
    ),
    (
        "      String msg(bool b) => b ? 'Cuenta suspendida. Contacta al administrador.' : '';\n"
        "      expect(msg(true), contains('suspendida'));",
        "      expect(mensajeCuentaBloqueada(true), contains('suspendida'));",
    ),
    (
        "      bool reembolso(String s) => s == 'esperando';\n"
        "      expect(reembolso('en_ruta'), isFalse);\n"
        "      expect(reembolso('esperando'), isTrue);",
        "      expect(reembolsoPosible('en_ruta'), isFalse);\n"
        "      expect(reembolsoPosible('esperando'), isTrue);",
    ),
    (
        "      bool validPct(double v) => v >= 0 && v <= 100;\n"
        "      expect(validPct(-1.0), isFalse);\n"
        "      expect(validPct(101.0), isFalse);\n"
        "      expect(validPct(20.0), isTrue);",
        "      expect(validarPorcentajeComision(-1.0), isFalse);\n"
        "      expect(validarPorcentajeComision(101.0), isFalse);\n"
        "      expect(validarPorcentajeComision(20.0), isTrue);",
    ),
    (
        "      String pago(int s, String? m) => s != 201 ? (m ?? 'Tarjeta rechazada') : 'ok';\n"
        "      expect(pago(400, 'Tarjeta rechazada'), equals('Tarjeta rechazada'));\n"
        "      expect(pago(201, null), equals('ok'));",
        "      expect(resultadoPagoCulqi(400, 'Tarjeta rechazada'), equals('Tarjeta rechazada'));\n"
        "      expect(resultadoPagoCulqi(201, null), equals('ok'));",
    ),
    (
        "      bool sesion = false;\n"
        "      String accion = sesion ? 'continuar' : 'solicitar login';\n"
        "      expect(accion, equals('solicitar login'));",
        "      expect(accionSesionExpirada(false), equals('solicitar login'));",
    ),
    (
        "      bool conn = false;\n"
        "      String res = conn ? 'datos frescos' : 'último estado conocido';\n"
        "      expect(res, equals('último estado conocido'));",
        "      expect(resultadoSinConexion(false), equals('último estado conocido'));",
    ),
    (
        "      String estado(String s) => s != 'esperando' ? 'Conductor no disponible' : '';\n"
        "      expect(estado('en_ruta'), isNotEmpty);",
        "      expect(mensajeConductorNoDisponible('en_ruta'), isNotEmpty);",
    ),
    (
        "      bool reserva = true;\n"
        "      if (!false) reserva = false; // pago fallido\n"
        "      expect(reserva, isFalse);",
        "      expect(pagoReservaCompletado(false), isFalse);",
    ),
    (
        "      final ocupados = {1, 3, 5};\n"
        "      expect(ocupados.contains(3), isTrue);\n"
        "      expect(ocupados.contains(2), isFalse);",
        "      final ocupados = {1, 3, 5};\n"
        "      expect(asientoPuedeSeleccionarse(2, ocupados), isTrue);\n"
        "      expect(asientoPuedeSeleccionarse(3, ocupados), isFalse);",
    ),
]

for old, new in SINGLE:
    content = content.replace(old, new)


def cp01_expectation(group_title: str) -> str:
    t = group_title.lower()
    if "registro de pasajero" in t or "registro de conductor" in t or "registro de administrador" in t:
        return "      expect(flujoRegistroPasajeroValido(), isTrue);"
    if "inicio de sesión" in t or "login" in t:
        return "      expect(flujoLoginValido(), isTrue);"
    if "punto de recojo" in t:
        return "      expect(flujoPuntoRecojoValido(), isTrue);"
    if "perfil" in t:
        return "      expect(flujoPerfilValido(), isTrue);"
    if "pago" in t or "pasarela" in t or "yape" in t or "tarjeta" in t:
        return "      expect(flujoPagoTarjetaValido(), isTrue);"
    if "tarifa" in t or "s/15" in t:
        return "      expect(flujoTarifaValida(), isTrue);"
    if "qr" in t:
        return "      expect(flujoQRValido(), isTrue);"
    if "reembolso" in t:
        return "      expect(reembolsoPosible('esperando'), isTrue);"
    if "bajada" in t or "bajarme" in t:
        return "      expect(bajadaPermitida('abordo'), isTrue);"
    if "comisión" in t or "comision" in t:
        return "      expect(validarPorcentajeComision(20.0), isTrue);"
    if "asiento" in t or "reserva de asiento" in t:
        return "      expect(calcularMontoPago(1), equals(kTarifaPorAsiento));"
    if "conductor" in t and ("activo" in t or "búsqueda" in t or "busqueda" in t or "listado" in t):
        return "      expect(conductorElegibleParaListado(cuentaActiva: true, estado: 'activo'), isTrue);"
    if "acompañante" in t or "acompanante" in t:
        return "      expect(validarDNI('12345678'), isNull);"
    if "llenado" in t or "lleno" in t:
        return "      expect(vehiculoLlenoParaSalir(ocupados: 4, capacidad: 4), isTrue);"
    if "eta" in t or "tiempo estimado" in t or "recorrido" in t or "mapa" in t and "viaje" in t:
        return "      expect(resultadoSinConexion(true), equals('datos frescos'));"
    return "      expect(validarCampoRequerido('ok'), isNull);"


def condicion_expectation(group_title: str, test_title: str) -> str:
    gt = group_title.lower()
    tt = test_title.lower()
    if "campo vacío" in tt:
        return (
            "      expect(validarPuntoRecojo(''), equals('Campo vacío'));\n"
            "      expect(validarPuntoRecojo(null), equals('Campo vacío'));"
        )
    if "campos requeridos incompletos" in tt or "campos vacíos" in tt:
        if "acompañante" in gt or "dni" in gt:
            return (
                "      expect(validarDNI(null), equals('Campo requerido'));\n"
                "      expect(validarDNI(''), equals('Campo requerido'));"
            )
        if "pago" in gt or "tarjeta" in gt:
            return "      expect(validacionFormatoPagoInvalido(), isTrue);"
        return (
            "      expect(validacionCamposIncompletos(null), isTrue);\n"
            "      expect(validacionCamposIncompletos(''), isTrue);"
        )
    if "formato de datos inválido" in tt:
        if "teléfono" in gt or "telefono" in gt:
            return "      expect(validacionFormatoTelefonoInvalido(), isTrue);"
        if "dni" in gt or "acompañante" in gt:
            return "      expect(validacionFormatoDniInvalido(), isTrue);"
        if "pago" in gt or "tarjeta" in gt:
            return "      expect(validacionFormatoPagoInvalido(), isTrue);"
        return "      expect(validacionFormatoEmailInvalido(), isTrue);"
    if "n/a" in tt and "tarifa" in gt:
        return "      expect(calcularMontoPago(1), equals(kTarifaPorAsiento));"
    if "n/a" in tt and "reembolso" in gt:
        return "      expect(reembolsoPosible('en_ruta'), isFalse);"
    if "salida forzada" in tt:
        return "      expect(vehiculoLlenoParaSalir(ocupados: 2, capacidad: 4, salidaForzadaAceptada: true), isTrue);"
    if "omite la calificación" in tt:
        return "      expect(validarCampoRequerido(null), isNotNull);"
    return (
        "      expect(validarCampoRequerido('dato'), isNull);\n"
        "      expect(validacionCamposIncompletos(null), isTrue);"
    )


# Procesar test por test dentro de cada group
group_pattern = re.compile(
    r"group\('(?P<group>[^']+)',\s*\(\)\s*\{(?P<body>.*?)\n  \}\);",
    re.DOTALL,
)


def transform_group(match: re.Match) -> str:
    group_title = match.group("group")
    body = match.group("body")

    # CP01 flujo exitoso
    body = re.sub(
        r"(test\('CP01 — Flujo exitoso[^']*', \(\) \{[^\n]*\n(?:      //[^\n]*\n)?)      expect\(true, isTrue\);",
        lambda m: m.group(1) + cp01_expectation(group_title),
        body,
    )

    # condicion = true
    def repl_condicion(m: re.Match) -> str:
        test_title = m.group(1)
        replacement = condicion_expectation(group_title, test_title)
        return f"test('{test_title}', () {{\n{replacement}"

    body = re.sub(
        r"test\('([^']+)', \(\) \{\n(?:      //[^\n]*\n)?      final condicion = true;\n      expect\(condicion, isTrue\);",
        repl_condicion,
        body,
    )

    return f"group('{group_title}', () {{{body}\n  }});"


content = group_pattern.sub(transform_group, content)

OUT.write_text(content, encoding="utf-8")
print(f"Reescrito: {OUT}")
