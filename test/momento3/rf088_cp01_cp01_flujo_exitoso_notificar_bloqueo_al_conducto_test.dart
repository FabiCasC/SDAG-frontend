import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-088: Notificación de bloqueo al conductor
// CP01 — Flujo exitoso — notificar bloqueo al conductor

void main() {
  test('CP01 — Flujo exitoso — notificar bloqueo al conductor', () {
      // ARRANGE — Cuenta del conductor suspendida con push habilitado.
      // ACT — Se evalúa notificación de bloqueo.
      final debeNotificar = debeNotificarBloqueoConductor(
        cuentaActiva: false,
        pushConductorHabilitado: true,
      );
      final mensaje = mensajeNotificacionBloqueoConductor();
      // ASSERT — Se notifica el bloqueo con mensaje de cuenta suspendida.
      expect(debeNotificar, isTrue);
      expect(mensaje, contains('suspendida'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP01 PASS — Flujo exitoso — notificar bloqueo al conductor');
  });
}
