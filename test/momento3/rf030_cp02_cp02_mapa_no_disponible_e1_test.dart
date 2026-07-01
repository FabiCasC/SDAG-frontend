import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/shared/maps/waze_service.dart';

// RF-030: Integración con Waze para selección de ruta
// CP02 — Mapa no disponible (E1)

void main() {
  test('CP02 — Mapa no disponible (E1)', () {
    // ARRANGE — Coordenadas de destino ausentes.
    // ACT — Validar disponibilidad Waze.
    final disponible = wazeDisponible(lat: null, lng: null);

    // ASSERT — Waze no disponible y mensaje de error definido.
    expect(disponible, isFalse);
    expect(mensajeWazeNoDisponible(), isNotEmpty);
    print('  ✅ CP02 PASS — Mapa no disponible (E1)');
  });
}
