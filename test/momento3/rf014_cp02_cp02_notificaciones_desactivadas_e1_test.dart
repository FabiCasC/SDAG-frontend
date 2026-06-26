import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-014: Notificación push cuando el conductor está cerca
// CP02 — Notificaciones desactivadas (E1)

void main() {
  test('CP02 — Notificaciones desactivadas (E1)', () {
      // ARRANGE — El pasajero tiene desactivadas las notificaciones push.
      const pushHabilitado = false;
      // ACT — Se intenta enviar la notificación push de llegada.
      final resultado = resultadoEnvioNotificacionPush(
        pushHabilitado: pushHabilitado,
        datosValidos: true,
      );
      // ASSERT — El envío se rechaza por push desactivado.
      expect(resultado, equals('Notificaciones push desactivadas'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Notificaciones desactivadas (E1)');
  });
}
