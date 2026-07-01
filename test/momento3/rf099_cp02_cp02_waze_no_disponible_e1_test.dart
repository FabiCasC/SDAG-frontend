import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/shared/maps/waze_service.dart';

// RF-099: Integración con Waze para tiempo estimado al pasajero
// CP02 — Waze no disponible (E1)

void main() {
  test('CP02 — Waze no disponible (E1)', () {
    // ARRANGE — Destino inválido.
    // ACT — Calcular ETA Waze.
    final eta = wazeEtaMinutes(
      fromLat: -11.93,
      fromLng: -76.69,
      toLat: null,
      toLng: null,
    );

    // ASSERT — Sin ETA.
    expect(eta, isNull);
    print('  ✅ CP02 PASS — Waze no disponible (E1)');
  });
}
