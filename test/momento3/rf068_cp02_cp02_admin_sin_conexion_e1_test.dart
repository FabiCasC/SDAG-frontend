import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-068: Notificación al administrador de nueva solicitud de pago
// CP02 — Admin sin conexión (E1)

void main() {
  test('CP02 — Admin sin conexión (E1)', () {
      // ARRANGE — Administrador sin conexión.
      const hayConexion = false;
      // ACT — Se evalúa entrega offline y regla de conexión del admin.
      final offline = offlineSyncStrategy(hayConexion);
      final puedeNotificar = puedeNotificarAdminSolicitudPago(
        solicitudValida: true,
        adminConectado: false,
      );
      // ASSERT — No se notifica al admin sin conexión.
      expect(offline, equals('último estado conocido'));
      expect(puedeNotificar, isFalse);
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Admin sin conexión (E1)');
  });
}
