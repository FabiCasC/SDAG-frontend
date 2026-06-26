import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-058: Notificación al conductor cuando el vehículo se llena
// CP02 — Notificaciones desactivadas (E1)

void main() {
  test('CP02 — Notificaciones desactivadas (E1)', () {
      // ARRANGE — Vehículo lleno pero push del conductor desactivado.
      const pushConductor = false;
      // ACT — Se evalúa el envío de notificación de llenado.
      final debeNotificar = debeNotificarVehiculoLleno(
        occupiedSeats: 4,
        capacity: 4,
        pushConductorHabilitado: pushConductor,
      );
      final resultado = resultadoEnvioNotificacionPush(
        pushHabilitado: pushConductor,
        datosValidos: true,
      );
      // ASSERT — No se notifica con push desactivado.
      expect(debeNotificar, isFalse);
      expect(resultado, equals('Notificaciones push desactivadas'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Notificaciones desactivadas (E1)');
  });
}
