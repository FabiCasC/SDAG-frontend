#!/usr/bin/env python3
"""Regenera tests Momento 3 usando solo lógica real de lib/ (sin mocks ni placeholders)."""
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "test" / "sdag_todos_los_rf_test.dart"
OUT_DIR = ROOT / "test" / "momento3"

# CP01 (y similares) por RF: expresión ACT real + imports extra necesarios
RF_CP01_ACT: dict[str, tuple[str, set[str]]] = {
    "RF-006": (
        "rutaCoincideDireccion(fromLabel: 'San Isidro', toLabel: 'Chosica', direction: kDirectionSiCho)",
        {"busqueda_utils.dart"},
    ),
    "RF-008": (
        "isRegisteredRouteDirection(kDirectionChoSi)",
        {"busqueda_utils.dart"},
    ),
    "RF-011": (
        "isEarlyDepartureAuthorized(votos: 2, activePassengerCount: 4)",
        {"forced_departure_utils.dart"},
    ),
    "RF-014": (
        "tituloNotificacionFcm('viaje_en_marcha')",
        {"push_notification_utils.dart"},
    ),
    "RF-022": (
        "calificacionConductorValida(5)",
        {"sdag_validators.dart"},
    ),
    "RF-015": (
        "puedeNotificarLlegadaConductor(haySesion: true, tripId: 'trip-001', passengerProfileId: 'p-001', pushDestinatarioHabilitado: true)",
        {"notification_utils.dart"},
    ),
    "RF-016": (
        "mensajeChatValido('Hola, ya voy llegando')",
        {"trip_message_utils.dart"},
    ),
    "RF-017": (
        "coordenadasConductorValidas(lat: -12.0464, lng: -76.9156)",
        {"waze_service.dart"},
    ),
    "RF-023": (
        "validarCampoRequerido('Noticia de ruta activa') == null",
        {"sdag_validators.dart"},
    ),
    "RF-024": (
        "conductorDisponibleParaReserva('esperando')",
        {"sdag_validators.dart"},
    ),
    "RF-026": (
        "manifestEntryBoardingValido('pendiente')",
        {"manifest_utils.dart"},
    ),
    "RF-027": (
        "manifestEntryBoardingValido('abordo')",
        {"manifest_utils.dart"},
    ),
    "RF-029": (
        "canDepartAfterCountdown(fullSince: DateTime.now().subtract(const Duration(minutes: 4)), now: DateTime.now(), isFull: true)",
        {"trip_rules.dart"},
    ),
    "RF-032": (
        "mensajeChatValido('Mensaje conductor')",
        {"trip_message_utils.dart"},
    ),
    "RF-039": (
        "validarCampoRequerido('Alerta vial en Chosica') == null",
        {"sdag_validators.dart"},
    ),
    "RF-040": (
        "validarCampoRequerido('Incidencia reportada') == null",
        {"sdag_validators.dart"},
    ),
    "RF-043": (
        "vehiculoRegistroValido(plate: 'ABC-123', totalSeats: 4)",
        {"vehicle_utils.dart"},
    ),
    "RF-047": (
        "isDriverEligibleForListing(cuentaActiva: true, estado: 'disponible')",
        {"busqueda_utils.dart"},
    ),
    "RF-048": (
        "isDriverEligibleForListing(cuentaActiva: true, estado: 'en_ruta')",
        {"busqueda_utils.dart"},
    ),
    "RF-049": (
        "canRefundForTripStatus('esperando')",
        {"trip_rules.dart"},
    ),
    "RF-050": (
        "calcularRecaudadoConductor(4) == 60.0",
        {"sdag_validators.dart"},
    ),
    "RF-051": (
        "isCommissionPercentValid(15.0)",
        {"payment_validation.dart"},
    ),
    "RF-056": (
        "directionRouteLabel(kDirectionChoSi) == 'Chosica → San Isidro'",
        {"busqueda_utils.dart"},
    ),
    "RF-063": (
        "canRefundForTripStatus('completado') == false",
        {"trip_rules.dart"},
    ),
    "RF-064": (
        "sessionExpiredAction(false) == 'solicitar login'",
        {"sdag_validators.dart"},
    ),
    "RF-065": (
        "PassengerAuthValidators.isValidEmail('pasajero@test.com')",
        {"passenger_auth_validators.dart"},
    ),
    "RF-066": (
        "sessionExpiredAction(true) == 'continuar'",
        {"sdag_validators.dart"},
    ),
    "RF-067": (
        "driverUnavailableMessage('en_ruta').isNotEmpty",
        {"trip_rules.dart"},
    ),
    "RF-073": (
        "calcularComisionConductor(480, 15) == 72.0",
        {"sdag_validators.dart"},
    ),
    "RF-074": (
        "isEarlyDepartureAuthorized(votos: 2, activePassengerCount: 4)",
        {"forced_departure_utils.dart"},
    ),
    "RF-078": (
        "validarCampoRequerido('Incidencia en ruta') == null",
        {"sdag_validators.dart"},
    ),
    "RF-081": (
        "blockedAccountMessage(accountActive: true).isEmpty",
        {"passenger_db_error_mapping.dart"},
    ),
    "RF-083": (
        "PassengerAuthValidators.isValidPeruPhone('987654321')",
        {"passenger_auth_validators.dart"},
    ),
    "RF-084": (
        "isCommissionPercentValid(0)",
        {"payment_validation.dart"},
    ),
    "RF-085": (
        "calcularRecaudadoConductor(2) == 30.0",
        {"sdag_validators.dart"},
    ),
    "RF-090": (
        "vehiculoRegistroValido(plate: 'ABC-123', totalSeats: 4)",
        {"vehicle_utils.dart"},
    ),
    "RF-092": (
        "isDriverEligibleForListing(cuentaActiva: false, estado: 'disponible') == false",
        {"busqueda_utils.dart"},
    ),
    "RF-093": (
        "isDriverEligibleForListing(cuentaActiva: true, estado: 'inactivo') == false",
        {"busqueda_utils.dart"},
    ),
    "RF-097": (
        "offlineSyncStrategy(false) == 'último estado conocido'",
        {"sdag_validators.dart"},
    ),
    "RF-098": (
        "matchesTripDirection(fromLabel: 'San Isidro', toLabel: 'Chosica', direction: kDirectionSiCho)",
        {"busqueda_utils.dart"},
    ),
    "RF-100": (
        "eventoAuditoriaValido('trip_auto_start', 'conductor')",
        {"audit_log_utils.dart"},
    ),
    "RF-102": (
        "PassengerAuthValidators.isValidEmail('conductor@test.com')",
        {"passenger_auth_validators.dart"},
    ),
    "RF-106": (
        "sessionExpiredAction(false) == 'solicitar login'",
        {"sdag_validators.dart"},
    ),
    "RF-107": (
        "mensajeArchivadoEsHistorico('archivado')",
        {"trip_message_utils.dart"},
    ),
    "RF-108": (
        "isRegisteredRouteDirection(kDirectionSiCho)",
        {"busqueda_utils.dart"},
    ),
    "RF-109": (
        "hasAvailableSeats(totalSeats: 4, occupiedSeats: 2)",
        {"busqueda_utils.dart"},
    ),
    "RF-110": (
        "isDriverEligibleForListing(cuentaActiva: true, estado: 'disponible')",
        {"busqueda_utils.dart"},
    ),
    "RF-111": (
        "isDriverEligibleForListing(cuentaActiva: true, estado: 'disponible')",
        {"busqueda_utils.dart"},
    ),
    "RF-112": (
        "PassengerAuthValidators.isValidEmail('admin@test.com')",
        {"passenger_auth_validators.dart"},
    ),
    "RF-115": (
        "canRefundForTripStatus('esperando')",
        {"trip_rules.dart"},
    ),
    "RF-117": (
        "puedeRegistrarPasajeroAusente(boardingStatus: 'pendiente', tripStatus: 'esperando')",
        {"manifest_utils.dart"},
    ),
    "RF-118": (
        "pickupStopsForDirection(kDirectionSiCho).isNotEmpty",
        {"busqueda_utils.dart"},
    ),
    "RF-119": (
        "isCommissionPercentValid(100)",
        {"payment_validation.dart"},
    ),
    "RF-123": (
        "expectedFromLabelForDirection(kDirectionChoSi) == 'Chosica'",
        {"busqueda_utils.dart"},
    ),
    "RF-124": (
        "canRefundForTripStatus('cancelado') == false",
        {"trip_rules.dart"},
    ),
}

IMPORT_MAP = {
    "sdag_validators.dart": "import 'package:sdag/core/validators/sdag_validators.dart';",
    "passenger_auth_validators.dart": "import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';",
    "passenger_db_error_mapping.dart": "import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';",
    "busqueda_utils.dart": "import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';",
    "notification_utils.dart": "import 'package:sdag/features/conductor/utils/notification_utils.dart';",
    "qr_scan_utils.dart": "import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';",
    "qr_security_utils.dart": "import 'package:sdag/features/conductor/utils/qr_security_utils.dart';",
    "payment_validation.dart": "import 'package:sdag/features/reserva/utils/payment_validation.dart';",
    "pickup_validation.dart": "import 'package:sdag/features/reserva/utils/pickup_validation.dart';",
    "trip_rules.dart": "import 'package:sdag/features/reserva/utils/trip_rules.dart';",
    "forced_departure_utils.dart": "import 'package:sdag/features/reserva/utils/forced_departure_utils.dart';",
    "waze_service.dart": "import 'package:sdag/shared/maps/waze_service.dart';",
    "push_notification_utils.dart": "import 'package:sdag/core/services/push_notification_utils.dart';",
    "trip_message_utils.dart": "import 'package:sdag/features/conductor/utils/trip_message_utils.dart';",
    "manifest_utils.dart": "import 'package:sdag/features/conductor/utils/manifest_utils.dart';",
    "vehicle_utils.dart": "import 'package:sdag/features/conductor/utils/vehicle_utils.dart';",
    "audit_log_utils.dart": "import 'package:sdag/core/services/audit_log_utils.dart';",
}

BASE_IMPORTS = [
    "import 'package:flutter_test/flutter_test.dart';",
]

FULL_HEADER = """import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/core/validators/sdag_validators.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/conductor/utils/qr_security_utils.dart';
import 'package:sdag/features/conductor/utils/trip_message_utils.dart';
import 'package:sdag/features/conductor/utils/manifest_utils.dart';
import 'package:sdag/features/conductor/utils/vehicle_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';
import 'package:sdag/features/reserva/utils/forced_departure_utils.dart';
import 'package:sdag/features/reserva/utils/seat_hold_utils.dart';
import 'package:sdag/shared/maps/waze_service.dart';
import 'package:sdag/core/services/push_notification_utils.dart';
import 'package:sdag/core/services/audit_log_utils.dart';
"""


def slug(text: str, max_len: int = 48) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"^CP\d+\s*—\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"[^a-zA-Z0-9]+", "_", text.lower()).strip("_")
    return text[:max_len].strip("_") or "caso"


def rf_num(group: str) -> str:
    m = re.match(r"(RF-\d+)", group)
    return m.group(1).replace("-", "").lower() if m else "rf000"


def cp_num(title: str) -> str:
    m = re.match(r"(CP\d+)", title, re.IGNORECASE)
    return m.group(1).lower() if m else "cp00"


def patch_master(content: str) -> str:
    """Reemplaza placeholders y tests fallidos en el archivo maestro."""
    lines = content.split("\n")
    current_rf = ""
    out: list[str] = []

    i = 0
    while i < len(lines):
        line = lines[i]
        m_rf = re.match(r"// (RF-\d+):", line.strip())
        if m_rf:
            current_rf = m_rf.group(1)

        if "PassengerAuthValidators.validateRequiredField('ok')" in line and current_rf in RF_CP01_ACT:
            act_expr, imports = RF_CP01_ACT[current_rf]
            indent = re.match(r"(\s*)", line).group(1)
            out.append(f"{indent}// Act — lógica real de lib/ ({current_rf})")
            out.append(f"{indent}final resultado1 = {act_expr};")
            i += 1
            continue

        # CP01 regenerado: expect isNull → isTrue cuando la expresión es booleana
        if "expect(resultado1, isNull)" in line:
            recent = "\n".join(out[-6:])
            if "== null" in recent or "isValidEmail" in recent or "isValidPeruPhone" in recent:
                out.append(line.replace("expect(resultado1, isNull)", "expect(resultado1, isTrue)"))
                i += 1
                continue
            if current_rf in RF_CP01_ACT:
                act_expr = RF_CP01_ACT[current_rf][0]
                if not any(
                    x in act_expr
                    for x in ("validateDni", "validateEmailField", "validateRequiredField", "validatePickup", "validateCard")
                ):
                    out.append(line.replace("expect(resultado1, isNull)", "expect(resultado1, isTrue)"))
                    i += 1
                    continue

        # RF-099 failing tests
        if current_rf == "RF-099" and "expect(false, isTrue)" in line:
            if "CP01" in "\n".join(lines[max(0, i - 8):i]):
                out.append("      final resultado1 = wazeEtaMinutes(fromLat: -12.0464, fromLng: -76.9156, toLat: -11.9375, toLng: -76.6934, googleEtaMinutes: 18);")
                out.append("      expect(resultado1, equals(18));")
            elif "CP02" in "\n".join(lines[max(0, i - 8):i]):
                out.append("      expect(wazeDisponible(lat: null, lng: -76.6934), isFalse);")
                out.append("      expect(mensajeWazeNoDisponible(), contains('Waze'));" )
            else:
                out.append("      expect(validateWazeCoordinates(lat: 999, lng: 0), isNotNull);")
            i += 1
            continue

        # lista vacía -> busquedaSinResultados (sin duplicar línea lista)
        if re.search(r"final lista = <Map<String, dynamic>>\[\];", line):
            if i + 1 < len(lines) and re.search(r"final lista = <Map<String, dynamic>>\[\];", lines[i + 1]):
                i += 1
            out.append(line)
            i += 1
            if i < len(lines) and "final isEmpty1 = lista.isEmpty" in lines[i]:
                out.append("      final isEmpty1 = busquedaSinResultados(lista.length);")
                i += 1
                continue
            continue

        # RF-055 CP01 ya corregido manualmente en maestro — no parchear aquí

        # RF-089 CP01 real vehicle capacity
        if current_rf == "RF-089" and "PassengerAuthValidators.isValidEmail('editado@test.com')" in line:
            out.append("      final resultado1 = vehiculoRegistroValido(plate: 'ABC-123', totalSeats: 4, label: 'Combi');")
            i += 1
            if i < len(lines) and "expect(resultado1, isTrue)" in lines[i]:
                out.append(lines[i])
                i += 1
            continue

        out.append(line)
        i += 1

    return "\n".join(out)


def collect_imports(body: str, rf: str) -> list[str]:
    needed = set()
    if rf in RF_CP01_ACT:
        needed.update(RF_CP01_ACT[rf][1])
    for key in IMPORT_MAP:
        if key.replace("_utils.dart", "") in body or key in body:
            needed.add(key)
    # heuristics from expressions in body
    tokens = [
        ("busqueda_utils.dart", ["kDirection", "matchesTripDirection", "pickupStops", "expectedFrom", "isRegisteredRoute", "hasAvailableSeats", "isDriverEligible"]),
        ("waze_service.dart", ["waze", "Waze", "buildWaze"]),
        ("qr_scan_utils.dart", ["buildPassengerQrData", "canScanReservationQr", "parseQrScan"]),
        ("qr_security_utils.dart", ["qrPersonalSignatureHash", "formatQrSignatureLabel", "buildSecurePassengerQr"]),
        ("trip_rules.dart", ["canRefund", "canMarkEarly", "canDepart", "driverUnavailable", "forcedDeparture"]),
        ("forced_departure_utils.dart", ["forcedDepartureVote"]),
        ("notification_utils.dart", ["puedeNotificar", "bannerNotificacion", "debeNotificar"]),
        ("payment_validation.dart", ["validateCard", "paymentAmount", "seatFare", "isCommission", "isNewCard"]),
        ("pickup_validation.dart", ["validatePickup"]),
        ("passenger_db_error_mapping.dart", ["registrationFailure", "authFailure", "placaDuplicate", "blockedAccount"]),
        ("passenger_auth_validators.dart", ["PassengerAuthValidators"]),
        ("sdag_validators.dart", ["validar", "calcular", "flujo", "offlineSync", "sessionExpired", "conductorDisponible", "vehiculoLleno", "mensajeConductor", "reembolso", "bajada", "eventoAuditoria", "coordenadasConductor", "tituloNotificacion", "mensajeChat", "manifestEntry", "vehiculoRegistro", "mensajeArchivado"]),
        ("push_notification_utils.dart", ["tituloNotificacionFcm", "cuerpoNotificacionFcm"]),
        ("trip_message_utils.dart", ["mensajeChatValido", "mensajeArchivado"]),
        ("manifest_utils.dart", ["manifestEntry"]),
        ("vehicle_utils.dart", ["vehiculoRegistro"]),
        ("audit_log_utils.dart", ["eventoAuditoria"]),
    ]
    for imp, kws in tokens:
        if any(k in body for k in kws):
            needed.add(imp)
    ordered = []
    for imp in IMPORT_MAP:
        if imp in needed:
            ordered.append(IMPORT_MAP[imp])
    return ordered


def extract_tests(content: str) -> list[tuple[str, str, str, str]]:
    items: list[tuple[str, str, str, str]] = []
    current_group = ""
    rf_comment = ""
    lines = content.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        gm = re.match(r"^// (RF-\d+:.+)$", line.strip())
        if gm:
            rf_comment = gm.group(1)
        gm2 = re.match(r"\s*group\('([^']+)'", line)
        if gm2:
            current_group = gm2.group(1)
        tm = re.match(r"\s*test\('([^']+)',\s*\(\)\s*\{", line)
        if tm:
            title = tm.group(1)
            i += 1
            depth = 1
            body_lines: list[str] = []
            while i < len(lines) and depth > 0:
                ln = lines[i]
                for ch in ln:
                    if ch == "{":
                        depth += 1
                    elif ch == "}":
                        depth -= 1
                if depth > 0:
                    body_lines.append(ln)
                i += 1
            body = "\n".join(body_lines)
            items.append((current_group, title, body, rf_comment))
            continue
        i += 1
    return items


def normalize_body(body: str) -> str:
    body = re.sub(
        r"// PRECONDICIÓN:.*?\n",
        "",
        body,
    )
    body = re.sub(
        r"// ACCIÓN:.*?\n",
        "",
        body,
    )
    body = re.sub(
        r"// RESULTADO ESPERADO:.*?\n",
        "",
        body,
    )
    body = re.sub(
        r"// RESULTADO OBTENIDO:.*\n",
        "",
        body,
    )
    return body


def main() -> None:
    import subprocess
    import sys

    patch_script = ROOT / "tool" / "patch_all_real_cp_tests.py"
    if patch_script.exists():
        subprocess.run([sys.executable, str(patch_script)], check=True)

    content = SRC.read_text(encoding="utf-8")
    content = patch_master(content)
    SRC.write_text(content, encoding="utf-8")

    tests = extract_tests(content)
    if OUT_DIR.exists():
        for old in OUT_DIR.glob("*.dart"):
            old.unlink()
    else:
        OUT_DIR.mkdir(parents=True)

    for group, title, body, rf_comment in tests:
        rf = rf_num(group)
        cp = cp_num(title)
        rf_id = re.match(r"(RF-\d+)", rf_comment or group)
        rf_key = rf_id.group(1) if rf_id else ""
        body = normalize_body(body)
        filename = f"{rf}_{cp}_{slug(title)}_test.dart"
        file_content = (
            FULL_HEADER
            + f"\n// {rf_comment or group}\n"
            + f"// {title}\n\n"
            + "void main() {\n"
            + f"  test('{title}', () {{\n"
            + body
            + "\n  });\n"
            + "}\n"
        )
        (OUT_DIR / filename).write_text(file_content, encoding="utf-8")

    placeholders = content.count("validateRequiredField('ok')")
    print(f"Regenerados {len(tests)} tests en {OUT_DIR.relative_to(ROOT)}")
    print(f"Placeholders restantes en maestro: {placeholders}")


if __name__ == "__main__":
    main()
