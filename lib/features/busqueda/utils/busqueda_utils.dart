/// Lógica pura de búsqueda extraída de [BusquedaService].
String expectedFromLabelForDirection(String direction) {
  return direction == 'si_cho' ? 'San Isidro' : 'Chosica';
}

bool matchesTripDirection({
  required String? fromLabel,
  required String direction,
}) {
  if (fromLabel == null || fromLabel.trim().isEmpty) return false;
  return fromLabel.trim() == expectedFromLabelForDirection(direction);
}

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
