import 'dart:convert';

import 'qr_scan_utils.dart';

/// Firma visual del boleto QR personal e intransferible (RF-055).
String qrPersonalSignatureHash({
  required String reservationId,
  required int seatNumber,
  required String passengerProfileId,
}) {
  final raw = '${reservationId.trim()}|$seatNumber|${passengerProfileId.trim()}';
  final bytes = utf8.encode(raw);
  var hash = 5381;
  for (final byte in bytes) {
    hash = ((hash << 5) + hash + byte) & 0x7FFFFFFF;
  }
  return hash.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 8);
}

/// Payload QR escaneable + hash de verificación.
String buildSecurePassengerQrPayload({
  required String reservationId,
  required int seatNumber,
  required String passengerProfileId,
}) {
  final base = buildPassengerQrData(reservaId: reservationId, seatNumber: seatNumber);
  final sig = qrPersonalSignatureHash(
    reservationId: reservationId,
    seatNumber: seatNumber,
    passengerProfileId: passengerProfileId,
  );
  return '$base|$sig';
}

String formatQrSignatureLabel(String hash) => 'SIG-$hash';
