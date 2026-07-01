import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/shared/maps/waze_service.dart';

// RF-099: Integración con Waze para tiempo estimado al pasajero
// CP01 — Flujo exitoso — integrar Waze para ETA al pasajero

void main() {
  test('CP01 — Flujo exitoso — integrar Waze para ETA al pasajero', () {
    // ARRANGE — Origen y destino válidos.
    // ACT — Calcular ETA con fallback Google.
    final eta = wazeEtaMinutes(
      fromLat: -11.9375,
      fromLng: -76.6934,
      toLat: -12.0992,
      toLng: -77.0349,
      googleEtaMinutes: 42,
    );

    // ASSERT — ETA disponible.
    expect(eta, equals(42));
    print('  ✅ CP01 PASS — Flujo exitoso — integrar Waze para ETA al pasajero');
  });
}
