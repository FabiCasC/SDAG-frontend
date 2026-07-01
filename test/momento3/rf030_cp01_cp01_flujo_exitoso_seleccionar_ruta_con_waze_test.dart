import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/shared/maps/waze_service.dart';

// RF-030: Integración con Waze para selección de ruta
// CP01 — Flujo exitoso — seleccionar ruta con Waze

void main() {
  test('CP01 — Flujo exitoso — seleccionar ruta con Waze', () {
    // ARRANGE — Coordenadas válidas Chosica → San Isidro.
    const fromLat = -11.9375;
    const fromLng = -76.6934;
    const toLat = -12.0992;
    const toLng = -77.0349;

    // ACT — Construir URI de navegación Waze.
    final uri = buildWazeRouteUri(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );

    // ASSERT — Waze disponible y URI contiene destino.
    expect(wazeDisponible(lat: toLat, lng: toLng), isTrue);
    expect(uri.toString(), contains('waze.com'));
    expect(uri.toString(), contains('navigate=yes'));
    print('  ✅ CP01 PASS — Flujo exitoso — seleccionar ruta con Waze');
  });
}
