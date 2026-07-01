import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/push_notification_service.dart';
import '../utils/forced_departure_utils.dart';

class EarlyDepartureVoteResult {
  const EarlyDepartureVoteResult({
    required this.ok,
    required this.message,
    this.votos = 0,
    this.totalPassengers = 0,
    this.departureAuthorized = false,
  });

  final bool ok;
  final String message;
  final int votos;
  final int totalPassengers;
  final bool departureAuthorized;
}

/// Registro de voto de salida anticipada vía RPC Supabase (RF-011).
class ForcedDepartureService {
  ForcedDepartureService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<EarlyDepartureVoteResult> registerVote({required String tripId}) async {
    try {
      final raw = await _client.rpc('register_early_departure_vote', params: {
        'p_trip_id': tripId,
      });

      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);

      final ok = map['ok'] == true;
      final votos = (map['votos'] as num?)?.toInt() ?? 0;
      final total = (map['total'] as num?)?.toInt() ?? 0;
      final authorized = map['departure_authorized'] == true;

      if (authorized) {
        PushNotificationService.instance.notifyForcedDepartureAuthorized(
          votos: votos,
          total: total,
        );
      }

      return EarlyDepartureVoteResult(
        ok: ok,
        message: map['error']?.toString() ??
            (authorized
                ? 'Salida anticipada autorizada'
                : 'Voto registrado ($votos/$total)'),
        votos: votos,
        totalPassengers: total,
        departureAuthorized: authorized,
      );
    } catch (e) {
      return EarlyDepartureVoteResult(
        ok: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<TripVoteSnapshot?> loadTripSnapshot(String tripId) async {
    final trip = await _client
        .from('trips')
        .select('id, status, votos_salida, created_at')
        .eq('id', tripId)
        .maybeSingle();

    if (trip == null) return null;

    final countRow = await _client
        .from('reservations')
        .select('id')
        .eq('trip_id', tripId)
        .inFilter('status', ['activa', 'completada']);

    final passengerCount = (countRow as List).length;
    final votos = (trip['votos_salida'] as num?)?.toInt() ?? 0;
    final createdAt = DateTime.tryParse(trip['created_at']?.toString() ?? '') ??
        DateTime.now();

    return TripVoteSnapshot(
      tripId: tripId,
      status: trip['status']?.toString() ?? 'esperando',
      votos: votos,
      passengerCount: passengerCount,
      createdAt: createdAt,
      threshold: earlyDepartureVoteThreshold(activePassengerCount: passengerCount),
      authorized: isEarlyDepartureAuthorized(
        votos: votos,
        activePassengerCount: passengerCount,
      ),
    );
  }
}

class TripVoteSnapshot {
  const TripVoteSnapshot({
    required this.tripId,
    required this.status,
    required this.votos,
    required this.passengerCount,
    required this.createdAt,
    required this.threshold,
    required this.authorized,
  });

  final String tripId;
  final String status;
  final int votos;
  final int passengerCount;
  final DateTime createdAt;
  final int threshold;
  final bool authorized;
}
