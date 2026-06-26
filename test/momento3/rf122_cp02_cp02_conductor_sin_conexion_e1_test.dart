import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-122: Notificación al conductor cuando un pasajero cancela su reserva
// CP02 — Conductor sin conexión (E1)

void main() {
  test('CP02 — Conductor sin conexión (E1)', () {
      // ARRANGE — Conductor sin conexión.
      const hayConexion = false;
      // ACT — Se evalúa entrega offline y regla de conexión.
      final offline = offlineSyncStrategy(hayConexion);
      final puedeNotificar = puedeNotificarCancelacionAlConductor(
        hayReserva: true,
        estadoViaje: 'esperando',
        conductorConectado: false,
      );
      // ASSERT — No se notifica sin conexión del conductor.
      expect(offline, equals('último estado conocido'));
      expect(puedeNotificar, isFalse);
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Conductor sin conexión (E1)');
  });
}
