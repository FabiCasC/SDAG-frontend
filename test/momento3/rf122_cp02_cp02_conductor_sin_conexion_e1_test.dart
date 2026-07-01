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

// RF-122: Notificación al conductor cuando un pasajero cancela su reserva
// CP02 — Conductor sin conexión (E1)

void main() {
  test('CP02 — Conductor sin conexión (E1)', () {
      // Arrange — Conductor sin conexión.
      const hayConexion = false;
      // Act — ejecutar la validación / regla de la app
      final offline = offlineSyncStrategy(hayConexion);
      final puedeNotificar = puedeNotificarCancelacionAlConductor(
        hayReserva: true,
        estadoViaje: 'esperando',
        conductorConectado: false,
      );
      // Assert — verificar el resultado esperado del CP
      expect(offline, equals('último estado conocido'));
      expect(puedeNotificar, isFalse);
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Conductor sin conexión (E1)');
  });
}
