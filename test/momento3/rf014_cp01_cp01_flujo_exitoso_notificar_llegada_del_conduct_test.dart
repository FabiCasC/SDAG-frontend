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
// CP01 — Flujo exitoso — notificar llegada del conductor

void main() {
  test('CP01 — Flujo exitoso — notificar llegada del conductor', () {
      // ARRANGE — Pasajero con push habilitado y viaje activo con datos válidos.
      const pushHabilitado = true;
      const tripId = 'trip-001';
      const passengerId = 'passenger-001';
      // ACT — Se evalúa si puede enviarse la notificación de llegada del conductor.
      final puedeEnviar = puedeNotificarLlegadaConductor(
        haySesion: true,
        tripId: tripId,
        passengerProfileId: passengerId,
        pushDestinatarioHabilitado: pushHabilitado,
      );
      final texto = textoNotificacionLlegadaConductor();
      // ASSERT — El sistema permite enviar la notificación con el texto de llegada.
      expect(puedeEnviar, isTrue);
      expect(texto, contains('llegando'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP01 PASS — Flujo exitoso — notificar llegada del conductor');
  });
}
