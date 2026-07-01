/// Reglas de salida anticipada por votación (RF-011, RF-074, RF-060).

const int kMinWaitingMinutesForEarlyDepartureVote = 10;

bool canVoteEarlyDeparture({
  required String tripStatus,
  required DateTime tripCreatedAt,
  required DateTime now,
  required bool alreadyVoted,
}) {
  if (alreadyVoted) return false;
  if (tripStatus != 'esperando') return false;
  final waited = now.difference(tripCreatedAt).inMinutes;
  return waited >= kMinWaitingMinutesForEarlyDepartureVote;
}

int earlyDepartureVoteThreshold({required int activePassengerCount}) {
  if (activePassengerCount <= 0) return 1;
  return (activePassengerCount * 0.5).ceil();
}

bool isEarlyDepartureAuthorized({
  required int votos,
  required int activePassengerCount,
}) {
  if (activePassengerCount <= 0) return false;
  return votos >= earlyDepartureVoteThreshold(activePassengerCount: activePassengerCount);
}

int waitingMinutesRemaining({
  required DateTime tripCreatedAt,
  required DateTime now,
}) {
  final elapsed = now.difference(tripCreatedAt).inMinutes;
  final left = kMinWaitingMinutesForEarlyDepartureVote - elapsed;
  return left.clamp(0, kMinWaitingMinutesForEarlyDepartureVote);
}
