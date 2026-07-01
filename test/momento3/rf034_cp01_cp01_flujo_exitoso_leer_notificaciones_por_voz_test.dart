import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/core/validators/sdag_validators.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/conductor/utils/qr_security_utils.dart';
import 'package:sdag/features/conductor/utils/trip_message_utils.dart';
import 'package:sdag/features/conductor/utils/manifest_utils.dart';
import 'package:sdag/features/conductor/utils/vehicle_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';
import 'package:sdag/features/reserva/utils/forced_departure_utils.dart';
import 'package:sdag/features/reserva/utils/seat_hold_utils.dart';
import 'package:sdag/shared/maps/waze_service.dart';
import 'package:sdag/core/services/push_notification_utils.dart';
import 'package:sdag/core/services/audit_log_utils.dart';

// RF-034: Comando de voz para notificaciones
// CP01 — Flujo exitoso — leer notificaciones por voz

void main() {
  test('CP01 — Flujo exitoso — leer notificaciones por voz', () {
      // Arrange — El conductor tiene activadas las notificaciones por voz.
      const vozHabilitada = true;
      const mensaje = 'Próxima parada: María';
      // Act — ejecutar la validación / regla de la app
      final banner = bannerNotificacionVoz(
        vozHabilitada: vozHabilitada,
        texto: mensaje,
      );
      // Assert — verificar el resultado esperado del CP
      expect(banner, equals('🔊 Próxima parada: María'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP01 PASS — Flujo exitoso — leer notificaciones por voz');
  });
}
