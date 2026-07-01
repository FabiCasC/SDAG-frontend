import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/shared/maps/waze_service.dart';

// RF-006: Ver ruta del conductor antes de reservar
// CP02 — Información de Waze no disponible (E1)

void main() {
  test('CP02 — Información de Waze no disponible (E1)', () {
    // ARRANGE — Destino sin coordenadas.
    // ACT — Consultar ETA Waze.
    final eta = wazeEtaMinutes(
      fromLat: -12.0,
      fromLng: -77.0,
      toLat: null,
      toLng: null,
      googleEtaMinutes: 20,
    );

    // ASSERT — ETA nula y mensaje de indisponibilidad.
    expect(eta, isNull);
    expect(mensajeWazeNoDisponible(), isNotEmpty);
    print('  ✅ CP02 PASS — Información de Waze no disponible (E1)');
  });
}
