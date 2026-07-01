import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/push_notification_service.dart';
import '../utils/payment_validation.dart';
import '../utils/trip_rules.dart';
import 'culqi_refund_service.dart';

/// Cancelación con reembolso Culqi + actualización Supabase (RF-012, RF-054).
class ReservationRefundService {
  ReservationRefundService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<RefundCancellationResult> cancelWithRefund({
    required String reservationId,
    required String passengerProfileId,
  }) async {
    final reservation = await _client
        .from('reservations')
        .select('id, trip_id, status, amount, seats')
        .eq('id', reservationId)
        .eq('passenger_profile_id', passengerProfileId)
        .maybeSingle();

    if (reservation == null) {
      return const RefundCancellationResult(
        success: false,
        message: 'Reserva no encontrada',
      );
    }

    final tripId = reservation['trip_id']?.toString();
    if (tripId == null || tripId.isEmpty) {
      return const RefundCancellationResult(
        success: false,
        message: 'Viaje no asociado',
      );
    }

    final trip = await _client
        .from('trips')
        .select('status, driver_id')
        .eq('id', tripId)
        .maybeSingle();

    final tripStatus = trip?['status']?.toString() ?? '';
    if (!canRefundForTripStatus(tripStatus)) {
      return RefundCancellationResult(
        success: false,
        message: tripStatus == 'en_ruta'
            ? 'El vehículo ya partió. No se puede cancelar ni reembolsar.'
            : 'No es posible reembolsar en el estado actual del viaje.',
        blockedByTripStatus: true,
      );
    }

    final payment = await _client
        .from('payments')
        .select('id, amount, receipt_number, status')
        .eq('reservation_id', reservationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final seats = (reservation['seats'] as List?)?.length ?? 1;
    final amount = (reservation['amount'] as num?)?.toDouble() ??
        seatFareTotalSoles(seats);
    final amountCents = (amount * 100).round();
    final chargeId = payment?['receipt_number']?.toString() ?? '';

    final refund = await requestCulqiRefund(
      chargeId: chargeId,
      amountCents: amountCents,
    );

    if (!refund.success) {
      return RefundCancellationResult(
        success: false,
        message: refund.message,
      );
    }

    await _client.from('reservations').update({
      'status': 'cancelada',
      'vehiculo_partio': false,
    }).eq('id', reservationId);

    if (payment != null) {
      await _client.from('payments').update({
        'status': 'reembolsado',
      }).eq('id', payment['id']);
    }

    await _client
        .from('profiles')
        .update({'has_active_reservation': false})
        .eq('id', passengerProfileId);

    final manifest = await _client
        .from('manifests')
        .select('id')
        .eq('trip_id', tripId)
        .maybeSingle();

    if (manifest != null) {
      await _client
          .from('manifest_entries')
          .update({'boarding_status': 'cancelado'})
          .eq('manifest_id', manifest['id'])
          .eq('passenger_profile_id', passengerProfileId);
    }

    final profile = await _client
        .from('profiles')
        .select('name, first_name, last_name')
        .eq('id', passengerProfileId)
        .maybeSingle();
    final passengerName = _passengerName(profile);

    PushNotificationService.instance.notifyReservationCancelled(
      passengerName: passengerName,
    );

    return RefundCancellationResult(
      success: true,
      message: 'Reserva cancelada y reembolso procesado',
      refundId: refund.refundId,
    );
  }

  String _passengerName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Pasajero';
    final name = profile['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final first = profile['first_name']?.toString().trim() ?? '';
    final last = profile['last_name']?.toString().trim() ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? 'Pasajero' : full;
  }
}

class RefundCancellationResult {
  const RefundCancellationResult({
    required this.success,
    required this.message,
    this.refundId,
    this.blockedByTripStatus = false,
  });

  final bool success;
  final String message;
  final String? refundId;
  final bool blockedByTripStatus;
}
