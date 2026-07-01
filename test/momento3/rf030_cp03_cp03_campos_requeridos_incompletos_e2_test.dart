import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/shared/maps/waze_service.dart';

// RF-030: Integración con Waze para selección de ruta
// CP03 — Campos requeridos incompletos (E2)

void main() {
  test('CP03 — Campos requeridos incompletos (E2)', () {
    // ARRANGE — Solo latitud presente.
    // ACT — Validar coordenadas Waze.
    final error = validateWazeCoordinates(lat: -11.93, lng: null);

    // ASSERT — Error por datos incompletos.
    expect(error, isNotNull);
    expect(error, contains('requeridas'));
    print('  ✅ CP03 PASS — Campos requeridos incompletos (E2)');
  });
}
