#!/usr/bin/env python3
"""Alinea tests UTP: imports de lib/, ARRANGE|ACT|ASSERT, sin sdag_validators."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

HEADER = """import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// ================================================================
// SDAG — UTP Semana 13 S2 — Momento 3 TDD (Guía Lab Pruebas de Software)
// Patrón ARRANGE | ACT | ASSERT sobre clases reales del proyecto (lib/)
// Ejecutar: flutter test test/sdag_tdd_momento3_test.dart --reporter expanded
// ================================================================
"""

REPLACEMENTS = [
    ("flujoRegistroPasajeroValido()", "(PassengerAuthValidators.isValidEmail('pasajero@test.com') && PassengerAuthValidators.isValidPeruPhone('987654321') && PassengerAuthValidators.isValidDni('12345678') && PassengerAuthValidators.isValidPassword('password123'))"),
    ("flujoLoginValido()", "(PassengerAuthValidators.isValidEmail('pasajero@test.com') && PassengerAuthValidators.isValidPassword('password123'))"),
    ("flujoPerfilValido()", "(PassengerAuthValidators.isValidEmail('editado@test.com') && PassengerAuthValidators.isValidPeruPhone('912345678'))"),
    ("flujoPuntoRecojoValido()", "(validatePickupPoint('Av. Principal 123, Chosica') == null)"),
    (
        "flujoPagoTarjetaValido()",
        "(isNewCardFormComplete(cardNumber: '4111111111111111', cvv: '123', expiry: '12/28', holder: 'Juan Perez') && validateCardPaymentFields(cardNumber: '4111111111111111', cvv: '123', expiry: '12/28', holder: 'Juan Perez') == null)",
    ),
    ("flujoTarifaValida()", "(seatFareTotalSoles(1) == 15.0 && paymentAmountCents(2) == 3000)"),
    (
        "flujoQRValido()",
        "canScanReservationQr(buildPassengerQrData(reservaId: '9b4020ff-4a93-48e4-9931-b861b5dfa482', seatNumber: 1))",
    ),
    ("validarCampoRequerido", "PassengerAuthValidators.validateRequiredField"),
    ("validarTelefono", "PassengerAuthValidators.validatePhoneField"),
    ("validarDNI", "PassengerAuthValidators.validateDniField"),
    ("validarPuntoRecojo", "validatePickupPoint"),
    ("validarPorcentajeComision", "isCommissionPercentValid"),
    ("mapRegistroErrorDuplicado", "registrationFailureType"),
    ("mapAuthExceptionError", "authFailureTypeFromExceptionType"),
    ("mapPlacaDuplicadaError", "placaDuplicateFailureType"),
    ("mensajeCuentaBloqueada(true)", "blockedAccountMessage(accountActive: false)"),
    ("mensajeCuentaBloqueada(false)", "blockedAccountMessage(accountActive: true)"),
    ("resultadoPagoCulqi", "culqiChargeResultMessage"),
    ("calcularMontoPago", "seatFareTotalSoles"),
    ("puedeEscanearQR", "canScanReservationQr"),
    ("generarQRData(", "buildPassengerQrData(reservaId: "),
    ("asientoPuedeSeleccionarse", "isSeatSelectable"),
    ("conductorElegibleParaListado", "isDriverEligibleForListing"),
    ("reembolsoPosible", "canRefundForTripStatus"),
    ("bajadaPermitida", "canMarkEarlyDropOff"),
    ("vehiculoLlenoParaSalir", "isVehicleFullForDeparture"),
    ("ocupados:", "occupiedSeats:"),
    ("capacidad:", "capacity:"),
    ("salidaForzadaAceptada:", "forcedDepartureAccepted:"),
    ("resultadoSinConexion", "offlineSyncStrategy"),
    ("accionSesionExpirada", "sessionExpiredAction"),
    ("pagoReservaCompletado", "reservationPaymentCompleted"),
    ("mensajeConductorNoDisponible", "driverUnavailableMessage"),
    ("validacionFormatoEmailInvalido()", "PassengerAuthValidators.validateEmailField('correo-sin-arroba') != null"),
    ("validacionFormatoPagoInvalido()", "validateCardPaymentFields(cardNumber: '1234', cvv: '12', expiry: '00/00', holder: 'X') != null"),
    ("equals(kTarifaPorAsiento)", "equals(15.0)"),
    ("import 'package:sdag/core/validators/sdag_validators.dart';", ""),
]

# generarQRData(uuid, 1) -> buildPassengerQrData(reservaId: uuid, seatNumber: 1)
GENERAR_QR = re.compile(
    r"buildPassengerQrData\(reservaId: ([^,]+), (\d+)\)"
)


def fix_qr_build(content: str) -> str:
    def repl(m: re.Match) -> str:
        return f"buildPassengerQrData(reservaId: {m.group(1)}, seatNumber: {m.group(2)})"

    return GENERAR_QR.sub(repl, content)


def fix_incompletos_bool(content: str) -> str:
    return re.sub(
        r"validacionCamposIncompletos\(([^)]+)\)",
        r"PassengerAuthValidators.validateRequiredField(\1) != null",
        content,
    )


def fix_comments(content: str) -> str:
    content = content.replace("// PRECONDICIÓN:", "// ARRANGE —")
    content = content.replace("// ACCIÓN:", "// ACT —")
    content = content.replace("// RESULTADO ESPERADO:", "// ASSERT —")
    content = content.replace(
        "// RESULTADO OBTENIDO: se completa al correr el test",
        "// Evidencia Momento 3: resultado obtenido al ejecutar flutter test",
    )
    return content


def transform(content: str) -> str:
    for old, new in REPLACEMENTS:
        content = content.replace(old, new)
    content = fix_qr_build(content)
    content = fix_incompletos_bool(content)
    content = fix_comments(content)
    # header
    content = re.sub(
        r"import 'package:flutter_test/flutter_test.dart';\nimport 'package:sdag/core/validators/sdag_validators\.dart';\n\n// =+\n//.*?\n// =+\n\n",
        HEADER,
        content,
        count=1,
        flags=re.DOTALL,
    )
    if "passenger_auth_validators.dart" not in content:
        content = content.replace(
            "import 'package:flutter_test/flutter_test.dart';",
            HEADER.rstrip() + "\n\n",
            1,
        )
    return content


def main() -> None:
    for name in ("sdag_tdd_momento3_test.dart", "sdag_todos_los_rf_test.dart"):
        path = ROOT / "test" / name
        if path.exists():
            text = transform(path.read_text(encoding="utf-8"))
            path.write_text(text, encoding="utf-8")
            print(f"Actualizado {name}")


if __name__ == "__main__":
    main()
