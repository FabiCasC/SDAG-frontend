/// Reglas de estado de viaje usadas en reserva, reembolso y salida del vehículo.

bool canRefundForTripStatus(String tripStatus) => tripStatus == 'esperando';

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
