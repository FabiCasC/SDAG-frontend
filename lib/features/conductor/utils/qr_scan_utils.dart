/// Utilidades de escaneo QR extraídas de [ConductorQrScannerScreen].
class QrScanPayload {
  const QrScanPayload({
    required this.reservaId,
    this.seatNumber,
  });

  final String reservaId;
  final int? seatNumber;
}

final RegExp reservationUuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

QrScanPayload parseQrScanValue(String qrValue) {
  String reservaId;
  int? asientoNumero;

  if (qrValue.contains('|')) {
    final partes = qrValue.split('|');
    reservaId = partes[0].trim();
    asientoNumero = int.tryParse(partes[1].trim());
  } else {
    reservaId = qrValue.trim();
  }

  if (reservaId.startsWith('res_')) {
    reservaId = reservaId.substring(4);
  }

  return QrScanPayload(reservaId: reservaId, seatNumber: asientoNumero);
}

bool isValidReservationUuid(String reservaId) => reservationUuidRegex.hasMatch(reservaId);

String buildPassengerQrData({required String reservaId, required int seatNumber}) {
  return '$reservaId|$seatNumber';
}

bool canScanReservationQr(String qrValue) {
  final payload = parseQrScanValue(qrValue);
  return isValidReservationUuid(payload.reservaId);
}

bool isSeatInReservation(int seatNumber, List<int> reservedSeats) {
  return reservedSeats.contains(seatNumber);
}
