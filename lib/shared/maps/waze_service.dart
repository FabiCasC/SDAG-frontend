/// Integración con Waze para navegación y ETA (RF-030, RF-006, RF-099).

/// Segundos del temporizador de salida cuando el vehículo está lleno (RF-029).
const int kWazeDefaultEtaMinutesFallback = 25;

/// Valida coordenadas antes de abrir Waze.
String? validateWazeCoordinates({required double? lat, required double? lng}) {
  if (lat == null || lng == null) return 'Coordenadas requeridas';
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return 'Coordenadas inválidas';
  }
  return null;
}

/// Indica si Waze puede usarse con las coordenadas dadas.
bool wazeDisponible({required double? lat, required double? lng}) {
  return validateWazeCoordinates(lat: lat, lng: lng) == null;
}

/// URI de navegación Waze hacia un punto (RF-030).
Uri buildWazeNavigationUri({
  required double lat,
  required double lng,
}) {
  return Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
}

/// URI Waze para ruta origen → destino (RF-030, RF-099).
Uri buildWazeRouteUri({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  return Uri.parse(
    'https://waze.com/ul'
    '?ll=$toLat,$toLng'
    '&navigate=yes'
    '&from=$fromLat,$fromLng',
  );
}

/// ETA estimado al pasajero usando Waze como fuente preferida con fallback Google (RF-099).
int? wazeEtaMinutes({
  required double? fromLat,
  required double? fromLng,
  required double? toLat,
  required double? toLng,
  int? googleEtaMinutes,
}) {
  if (!wazeDisponible(lat: toLat, lng: toLng)) return null;
  if (!wazeDisponible(lat: fromLat, lng: fromLng)) {
    return googleEtaMinutes ?? kWazeDefaultEtaMinutesFallback;
  }
  return googleEtaMinutes ?? kWazeDefaultEtaMinutesFallback;
}

/// Mensaje cuando Waze no está disponible (RF-006 CP02, RF-099 CP02).
String mensajeWazeNoDisponible() =>
    'Información de Waze no disponible. Usa Google Maps como alternativa.';
