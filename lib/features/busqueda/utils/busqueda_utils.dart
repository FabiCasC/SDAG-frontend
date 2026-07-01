/// Lógica pura de búsqueda extraída de [BusquedaService].

const String kDirectionSiCho = 'si_cho';
const String kDirectionChoSi = 'cho_si';

String expectedFromLabelForDirection(String direction) {
  return direction == kDirectionSiCho ? 'San Isidro' : 'Chosica';
}

String expectedToLabelForDirection(String direction) {
  return direction == kDirectionSiCho ? 'Chosica' : 'San Isidro';
}

String directionRouteLabel(String direction) {
  return '${expectedFromLabelForDirection(direction)} → ${expectedToLabelForDirection(direction)}';
}

bool isRegisteredRouteDirection(String? direction) {
  return direction == kDirectionSiCho || direction == kDirectionChoSi;
}

/// Paraderos de subida según sentido del viaje (RF-098).
List<String> pickupStopsForDirection(String direction) {
  switch (direction) {
    case kDirectionSiCho:
      return const [
        'Av. Javier Prado (San Isidro)',
        'Av. República de Panamá',
        'Av. Tomás Marsano',
      ];
    case kDirectionChoSi:
      return const [
        'Plaza de Armas (Chosica)',
        'Av. Nicolás de Piérola (Chosica)',
        'Mercado Central de Chosica',
      ];
    default:
      return const [];
  }
}

String primaryPickupHintForDirection(String direction) {
  final stops = pickupStopsForDirection(direction);
  return stops.isEmpty ? '—' : stops.first;
}

bool matchesTripDirection({
  required String? fromLabel,
  required String? toLabel,
  required String direction,
}) {
  if (fromLabel == null || fromLabel.trim().isEmpty) return false;
  if (toLabel == null || toLabel.trim().isEmpty) return false;
  return fromLabel.trim() == expectedFromLabelForDirection(direction) &&
      toLabel.trim() == expectedToLabelForDirection(direction);
}

bool busquedaSinResultados(int viajesEncontrados) => viajesEncontrados <= 0;

bool isDriverEligibleForListing({
  required bool? cuentaActiva,
  required String? estado,
}) {
  if (cuentaActiva == false) return false;
  if ((estado ?? '').toLowerCase() == 'inactivo') return false;
  return true;
}

int countOccupiedSeatsFromReservationRows(List<dynamic> reservationRows) {
  var occupied = 0;
  for (final raw in reservationRows) {
    if (raw is! Map) continue;
    final seats = raw['seats'];
    if (seats is List) occupied += seats.length;
  }
  return occupied;
}

int availableSeatsCount({
  required int totalSeats,
  required int occupiedSeats,
}) {
  return totalSeats - occupiedSeats;
}

bool hasAvailableSeats({
  required int totalSeats,
  required int occupiedSeats,
}) {
  return availableSeatsCount(totalSeats: totalSeats, occupiedSeats: occupiedSeats) > 0;
}

String buildRouteLabel({
  String? name,
  required String from,
  required String to,
}) {
  final trimmedName = name?.trim();
  if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
  return '$from → $to';
}
