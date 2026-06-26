import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-004: Edición de perfil de pasajero
// CP02 — Correo duplicado (E1)

void main() {
  test('CP02 — Correo duplicado (E1)', () {
      // ARRANGE — Existe un intento de registro/edición con un correo que ya está en la base de datos.
      const mensajeEmailDuplicado = 'email already registered';
      // ACT — Se ejecuta la lógica de negocio/validación de la app: registrationFailureType().
      final resultado1 = registrationFailureType(mensajeEmailDuplicado);
      // ASSERT — El sistema debe responder: equals('EmailDuplicadoFailure').
      expect(resultado1, equals('EmailDuplicadoFailure'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Correo duplicado (E1)');
  });
}
