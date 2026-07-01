import 'package:flutter_test/flutter_test.dart';
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

// RF-009: Ingreso de datos de acompañantes
// CP03 — Campos vacíos (E2)

void main() {
  test('CP03 — Campos vacíos (E2)', () {
      // Arrange — datos de entrada del caso de prueba
      const campoNulo = null;
      const dniValor2020 = '';
      // Act — ejecutar la validación / regla de la app
      final resultado1 = PassengerAuthValidators.validateDniField(campoNulo);
      final resultado2 = PassengerAuthValidators.validateDniField(dniValor2020);
      // Assert — verificar el resultado esperado del CP
      expect(resultado1, equals('Campo requerido'));
      expect(resultado2, equals('Campo requerido'));
      print('  ✅ CP03 PASS — Campos vacíos (E2)');
  });
}
