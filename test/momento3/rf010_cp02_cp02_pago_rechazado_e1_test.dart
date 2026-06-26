import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';

// RF-010: Pago de asiento mediante pasarela
// CP02 — Pago rechazado (E1)

void main() {
  test('CP02 — Pago rechazado (E1)', () {
      // ARRANGE — La pasarela de pago responde con un código de error o el pago no se completa.
      const codigoHttp1 = 400;
      const mensajePago1 = 'Tarjeta rechazada';
      const codigoHttp2 = 201;
      const mensajePago2 = null;
      // ACT — Se ejecuta la lógica de negocio/validación de la app: culqiChargeResultMessage().
      final resultado1 = culqiChargeResultMessage(codigoHttp1, mensajePago1);
      final resultado2 = culqiChargeResultMessage(codigoHttp2, mensajePago2);
      // ASSERT — El sistema debe responder: equals('Tarjeta rechazada'); equals('ok').
      expect(resultado1, equals('Tarjeta rechazada'));
      expect(resultado2, equals('ok'));
      // Evidencia Momento 3: resultado obtenido al ejecutar flutter test
      print('  ✅ CP02 PASS — Pago rechazado (E1)');
  });
}
