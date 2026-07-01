/// Bloqueo temporal de asientos durante la reserva (RF-120).

/// Duración del hold mientras el pasajero completa el flujo de reserva.
const Duration kSeatHoldDuration = Duration(minutes: 10);

/// Segundos restantes antes de liberar asientos bloqueados.
int seatHoldRemainingSeconds({
  required DateTime? holdStartedAt,
  required DateTime now,
  Duration holdDuration = kSeatHoldDuration,
}) {
  if (holdStartedAt == null) return holdDuration.inSeconds;
  final elapsed = now.difference(holdStartedAt).inSeconds;
  return (holdDuration.inSeconds - elapsed).clamp(0, holdDuration.inSeconds);
}

/// Indica si el bloqueo de asientos expiró y deben liberarse.
bool seatHoldExpired({
  required DateTime? holdStartedAt,
  required DateTime now,
  Duration holdDuration = kSeatHoldDuration,
}) {
  if (holdStartedAt == null) return false;
  return now.difference(holdStartedAt) >= holdDuration;
}

/// Formatea el temporizador visible para el pasajero.
String formatSeatHoldCountdown(int remainingSeconds) {
  final m = remainingSeconds ~/ 60;
  final s = remainingSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
