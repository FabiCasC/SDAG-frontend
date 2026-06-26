import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-060: Notificación de solicitud de forzar salida a pasajeros
// CP02 — Algún pasajero rechaza (E1)

void main() {
  test('CP02 — Algún pasajero rechaza (E1)', () {
      // ARRANGE — Al menos un pasajero rechazó la salida forzada.
      // ACT — Se evalúa el resultado de la votación.
      final rechazada = forzarSalidaRechazadaPorPasajero(rechazos: 1);
      // ASSERT — La solicitud queda rechazada.
      expect(rechazada, isTrue);
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Algún pasajero rechaza (E1)');
  });
}
