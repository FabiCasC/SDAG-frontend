/// Reglas de estado de viaje usadas en reserva, reembolso y salida del vehículo.

/// Temporizador de 3 minutos para partir cuando el vehículo está lleno (RF-029).
const int kDepartureCountdownSeconds = 180;

/// Minutos promedio estimados por asiento restante (RF-096).
const double kAvgMinutesPerRemainingSeat = 4.5;

bool canRefundForTripStatus(String tripStatus) => tripStatus == 'esperando';

/// RF-054 — bloqueo de cancelación/reembolso si el viaje ya partió.
bool canCancelReservationForTripStatus(String tripStatus) =>
    tripStatus == 'esperando';

bool isTripDeparted(String tripStatus) =>
    tripStatus == 'en_ruta' || tripStatus == 'completado';

bool canMarkEarlyDropOff(String boardingStatus) => boardingStatus == 'abordo';

bool isVehicleFullForDeparture({
  required int occupiedSeats,
  required int capacity,
  bool forcedDepartureAccepted = false,
}) {
  if (forcedDepartureAccepted) return true;
  return occupiedSeats >= capacity;
}

String offlineSyncStrategy(bool isConnected) {
  return isConnected ? 'datos frescos' : 'último estado conocido';
}

String driverUnavailableMessage(String tripStatus) {
  return tripStatus != 'esperando' ? 'Conductor no disponible' : '';
}

String sessionExpiredAction(bool sessionActive) {
  return sessionActive ? 'continuar' : 'solicitar login';
}

bool reservationPaymentCompleted(bool paymentSucceeded) => paymentSucceeded;

bool isCommissionPercentValid(double percent) => percent >= 0 && percent <= 100;

bool isSeatSelectable(int seatNumber, Set<int> occupiedSeats) {
  return !occupiedSeats.contains(seatNumber);
}

/// RF-057 — misma regla de vehículo lleno en ida y retorno (Chosica ↔ San Isidro).
bool isVehicleFullForRouteDirection({
  required int occupiedSeats,
  required int capacity,
  required String direction,
  bool forcedDepartureAccepted = false,
}) {
  assert(direction == 'si_cho' || direction == 'cho_si' || direction.isEmpty);
  return isVehicleFullForDeparture(
    occupiedSeats: occupiedSeats,
    capacity: capacity,
    forcedDepartureAccepted: forcedDepartureAccepted,
  );
}

/// Segundos restantes del temporizador de salida (RF-029).
int departureCountdownRemainingSeconds({
  required DateTime? fullSince,
  required DateTime now,
  int totalSeconds = kDepartureCountdownSeconds,
}) {
  if (fullSince == null) return totalSeconds;
  final elapsed = now.difference(fullSince).inSeconds;
  return (totalSeconds - elapsed).clamp(0, totalSeconds);
}

/// Puede iniciar el viaje tras el temporizador o forzado de salida (RF-029).
bool canDepartAfterCountdown({
  required DateTime? fullSince,
  required DateTime now,
  required bool isFull,
  bool forcedDeparture = false,
}) {
  if (forcedDeparture) return true;
  if (!isFull) return false;
  return departureCountdownRemainingSeconds(fullSince: fullSince, now: now) <= 0;
}

/// RF-096 — tiempo estimado de llenado del vehículo (minutos).
int estimateVehicleFillMinutes({
  required int occupiedSeats,
  required int capacity,
  double avgMinutesPerSeat = kAvgMinutesPerRemainingSeat,
}) {
  if (capacity <= 0) return 0;
  final remaining = capacity - occupiedSeats;
  if (remaining <= 0) return 0;
  return (remaining * avgMinutesPerSeat).ceil();
}

String formatDepartureCountdown(int remainingSeconds) {
  final m = remainingSeconds ~/ 60;
  final s = remainingSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
