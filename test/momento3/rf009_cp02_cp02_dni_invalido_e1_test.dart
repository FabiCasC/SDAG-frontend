import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-009: Ingreso de datos de acompañantes
// CP02 — DNI inválido (E1)

void main() {
  test('CP02 — DNI inválido (E1)', () {
      // ARRANGE — Se ingresa un DNI que no cumple la regla de 8 dígitos.
      const dniInvalido = '1234';
      const dniValido = '12345678';
      // ACT — Se ejecuta la lógica de negocio/validación de la app: PassengerAuthValidators.validateDniField().
      final resultado1 = PassengerAuthValidators.validateDniField(dniInvalido);
      final resultado2 = PassengerAuthValidators.validateDniField(dniValido);
      // ASSERT — El sistema debe responder: equals('DNI inválido'); isNull.
      expect(resultado1, equals('DNI inválido'));
      expect(resultado2, isNull);
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — DNI inválido (E1)');
  });
}
