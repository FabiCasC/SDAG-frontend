import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-034: Comando de voz para notificaciones
// CP01 — Flujo exitoso — leer notificaciones por voz

void main() {
  test('CP01 — Flujo exitoso — leer notificaciones por voz', () {
      // ARRANGE — El conductor tiene activadas las notificaciones por voz.
      const vozHabilitada = true;
      const mensaje = 'Próxima parada: María';
      // ACT — Se emite el banner de voz como en el provider del conductor.
      final banner = bannerNotificacionVoz(
        vozHabilitada: vozHabilitada,
        texto: mensaje,
      );
      // ASSERT — Se genera el banner audible con el prefijo 🔊.
      expect(banner, equals('🔊 Próxima parada: María'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP01 PASS — Flujo exitoso — leer notificaciones por voz');
  });
}
