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

// RF-099: Integración con Waze para tiempo estimado al pasajero
// CP01 — Flujo exitoso — integrar Waze para ETA al pasajero

void main() {
  test('CP01 — Flujo exitoso — integrar Waze para ETA al pasajero', () {
      // Arrange — escenario «Flujo exitoso — integrar Waze para ETA al pasajero» (Integración con Waze para tiempo estimado al pasajero)
      // Act — ejecutar la validación / regla de la app
      // Assert — verificar el resultado esperado del CP
      final resultado1 = wazeEtaMinutes(fromLat: -12.0464, fromLng: -76.9156, toLat: -11.9375, toLng: -76.6934, googleEtaMinutes: 18);
      expect(resultado1, equals(18));
      print('  ✅ CP01 PASS — Flujo exitoso — integrar Waze para ETA al pasajero');
  });
}
