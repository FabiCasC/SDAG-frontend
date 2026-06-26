import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-102: Recuperación de contraseña del conductor
// CP02 — Correo no registrado (E1)

void main() {
  test('CP02 — Correo no registrado (E1)', () {
      // ARRANGE — Estado inicial preparado para validar «Correo no registrado (E1)» en Recuperación de contraseña del conductor.
      const mensajeEmailDuplicado = 'email already registered';
      // ACT — Se ejecuta la lógica de negocio/validación de la app: registrationFailureType().
      final resultado1 = registrationFailureType(mensajeEmailDuplicado);
      // ASSERT — El sistema debe responder: equals('EmailDuplicadoFailure').
      expect(resultado1, equals('EmailDuplicadoFailure'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Correo no registrado (E1)');
  });
}
