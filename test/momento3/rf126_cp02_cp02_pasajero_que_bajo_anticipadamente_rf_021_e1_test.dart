import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-126: Notificación al pasajero cuando el conductor completa la ruta
// CP02 — Pasajero que bajó anticipadamente (RF-021) (E1)

void main() {
  test('CP02 — Pasajero que bajó anticipadamente (RF-021) (E1)', () {
      // ARRANGE — Pasajero que bajó anticipadamente (RF-021).
      // ACT — Se evalúa notificación con pasajero ya no en viaje.
      final puedeNotificar = puedeNotificarRutaCompletadaAlPasajero(
        rutaCompletada: true,
        pasajeroSigueEnViaje: false,
        pasajeroConectado: true,
      );
      // ASSERT — No se notifica a quien ya bajó.
      expect(puedeNotificar, isFalse);
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Pasajero que bajó anticipadamente (RF-021) (E1)');
  });
}
