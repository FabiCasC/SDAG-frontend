import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/shared/maps/waze_service.dart';

// RF-099: Integración con Waze para tiempo estimado al pasajero
// CP03 — Campos requeridos incompletos (E2)

void main() {
  test('CP03 — Campos requeridos incompletos (E2)', () {
    // ARRANGE — Coordenadas incompletas.
    // ACT — Validar coordenadas.
    final error = validateWazeCoordinates(lat: null, lng: -77.03);

    // ASSERT — Error de validación.
    expect(error, isNotNull);
    print('  ✅ CP03 PASS — Campos requeridos incompletos (E2)');
  });
}
