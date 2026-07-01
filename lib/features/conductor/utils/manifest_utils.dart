/// Reglas del manifiesto electrónico (RF-026, RF-027, RF-117).

bool manifestEntryBoardingValido(String boardingStatus) {
  const valid = {'pendiente', 'abordo', 'no_abordo'};
  return valid.contains(boardingStatus.trim().toLowerCase());
}

bool puedeRegistrarPasajeroAusente({
  required String boardingStatus,
  required String tripStatus,
}) {
  return boardingStatus == 'pendiente' && tripStatus == 'esperando';
}

bool pasajeroAusenteRegistrado(String boardingStatus) {
  return boardingStatus == 'no_abordo';
}
