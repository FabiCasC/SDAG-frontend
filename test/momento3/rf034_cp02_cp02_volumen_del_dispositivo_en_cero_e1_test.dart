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
// CP02 — Volumen del dispositivo en cero (E1)

void main() {
  test('CP02 — Volumen del dispositivo en cero (E1)', () {
      // ARRANGE — Las notificaciones por voz están desactivadas (volumen en cero).
      const vozHabilitada = false;
      // ACT — Se intenta leer una notificación por voz.
      final banner = bannerNotificacionVoz(
        vozHabilitada: vozHabilitada,
        texto: 'Pasajero cerca del punto de recojo',
      );
      // ASSERT — No se emite banner de voz.
      expect(banner, isNull);
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Volumen del dispositivo en cero (E1)');
  });
}
