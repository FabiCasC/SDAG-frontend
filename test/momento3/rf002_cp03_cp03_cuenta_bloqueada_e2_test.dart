import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-002: Inicio de sesión de pasajero
// CP03 — Cuenta bloqueada (E2)

void main() {
  test('CP03 — Cuenta bloqueada (E2)', () {
      // ARRANGE — La cuenta del usuario está marcada como suspendida/bloqueada.
      const cuentaBloqueada = true;
      // ACT — Se ejecuta blockedAccountMessage() del mapeo de errores de la app.
      final resultado1 = blockedAccountMessage(accountActive: !cuentaBloqueada);
      // ASSERT — El sistema debe responder: contains('suspendida').
      expect(resultado1, contains('suspendida'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP03 PASS — Cuenta bloqueada (E2)');
  });
}
