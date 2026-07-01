import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/route_polyline_model.dart';
import '../utils/seat_hold_utils.dart';

class ReservaAcompanante {
  const ReservaAcompanante({
    required this.seatNumber,
    required this.fullName,
    required this.dni,
    required this.phone,
  });

  final int seatNumber;
  final String fullName;
  final String dni;
  final String phone;
}

class ReservaDriverInfo {
  const ReservaDriverInfo({
    required this.tripId,
    required this.driverId,
    required this.name,
    required this.plate,
    required this.vehicleType,
    required this.totalSeats,
    required this.routeLabel,
    required this.rating,
    required this.ratingCount,
    required this.status,
    this.routePolyline,
  });

  final String tripId;
  final String driverId;
  final String name;
  final String plate;
  final String vehicleType;
  final int totalSeats;
  final String routeLabel;
  final double rating;
  final int ratingCount;
  final String status;
  final RoutePolyline? routePolyline;
}

class ReservaState {
  const ReservaState({
    required this.reservaId,
    required this.conductorSeleccionado,
    required this.asientosSeleccionados,
    required this.acompanantes,
    required this.puntoRecojo,
    this.pickupLat,
    this.pickupLng,
    required this.vehiculoPartio,
    required this.additionalChargePending,
    required this.additionalChargeAmount,
    this.seatHoldStartedAt,
  });

  final String? reservaId;
  final ReservaDriverInfo? conductorSeleccionado;
  final List<int> asientosSeleccionados;
  final Map<int, ReservaAcompanante> acompanantes;
  final String? puntoRecojo;
  final double? pickupLat;
  final double? pickupLng;
  final bool vehiculoPartio;
  final bool additionalChargePending;
  final double additionalChargeAmount;
  final DateTime? seatHoldStartedAt;

  double get montoTotal => asientosSeleccionados.length * 15.0;
  double get montoTotalFinal => montoTotal + (additionalChargePending ? additionalChargeAmount : 0.0);

  ReservaState copyWith({
    String? reservaId,
    ReservaDriverInfo? conductorSeleccionado,
    List<int>? asientosSeleccionados,
    Map<int, ReservaAcompanante>? acompanantes,
    String? puntoRecojo,
    double? pickupLat,
    double? pickupLng,
    bool clearPickup = false,
    bool clearPickupCoords = false,
    bool? vehiculoPartio,
    bool? additionalChargePending,
    double? additionalChargeAmount,
    bool clearAdditionalCharge = false,
    DateTime? seatHoldStartedAt,
    bool clearSeatHold = false,
  }) {
    return ReservaState(
      reservaId: reservaId ?? this.reservaId,
      conductorSeleccionado: conductorSeleccionado ?? this.conductorSeleccionado,
      asientosSeleccionados: asientosSeleccionados ?? this.asientosSeleccionados,
      acompanantes: acompanantes ?? this.acompanantes,
      puntoRecojo: clearPickup ? null : (puntoRecojo ?? this.puntoRecojo),
      pickupLat: clearPickupCoords || clearPickup ? null : (pickupLat ?? this.pickupLat),
      pickupLng: clearPickupCoords || clearPickup ? null : (pickupLng ?? this.pickupLng),
      vehiculoPartio: vehiculoPartio ?? this.vehiculoPartio,
      additionalChargePending: clearAdditionalCharge
          ? false
          : (additionalChargePending ?? this.additionalChargePending),
      additionalChargeAmount:
          clearAdditionalCharge ? 0.0 : (additionalChargeAmount ?? this.additionalChargeAmount),
      seatHoldStartedAt: clearSeatHold ? null : (seatHoldStartedAt ?? this.seatHoldStartedAt),
    );
  }

  static const empty = ReservaState(
    reservaId: null,
    conductorSeleccionado: null,
    asientosSeleccionados: <int>[],
    acompanantes: <int, ReservaAcompanante>{},
    puntoRecojo: null,
    pickupLat: null,
    pickupLng: null,
    vehiculoPartio: false,
    additionalChargePending: false,
    additionalChargeAmount: 0.0,
    seatHoldStartedAt: null,
  );
}

class ReservaController extends StateNotifier<ReservaState> {
  ReservaController() : super(ReservaState.empty);

  void startWithDriver(ReservaDriverInfo driver) {
    if (driver.tripId.trim().isEmpty) {
      return;
    }
    state = ReservaState(
      reservaId: null,
      conductorSeleccionado: driver,
      asientosSeleccionados: const <int>[],
      acompanantes: const <int, ReservaAcompanante>{},
      puntoRecojo: null,
      pickupLat: null,
      pickupLng: null,
      vehiculoPartio: false,
      additionalChargePending: false,
      additionalChargeAmount: 0.0,
      seatHoldStartedAt: null,
    );
  }

  void setSelectedSeats(List<int> seats) {
    final normalized = seats.toSet().toList()..sort();
    final keep = <int, ReservaAcompanante>{};
    for (final s in normalized) {
      final existing = state.acompanantes[s];
      if (existing != null) keep[s] = existing;
    }
    final holdStart = normalized.isEmpty
        ? null
        : (state.seatHoldStartedAt ?? DateTime.now());
    state = state.copyWith(
      asientosSeleccionados: normalized,
      acompanantes: keep,
      seatHoldStartedAt: holdStart,
      clearSeatHold: normalized.isEmpty,
    );
  }

  /// RF-120 — libera asientos cuando expira el bloqueo temporal.
  void clearSeatHoldIfExpired(DateTime now) {
    if (state.seatHoldStartedAt == null || state.asientosSeleccionados.isEmpty) return;
    if (!seatHoldExpired(holdStartedAt: state.seatHoldStartedAt, now: now)) return;
    state = state.copyWith(
      asientosSeleccionados: const <int>[],
      acompanantes: const <int, ReservaAcompanante>{},
      clearSeatHold: true,
    );
  }

  void setAcompanante(ReservaAcompanante a) {
    final next = Map<int, ReservaAcompanante>.from(state.acompanantes);
    next[a.seatNumber] = a;
    state = state.copyWith(acompanantes: next);
  }

  void setPickup(String pickup) {
    state = state.copyWith(puntoRecojo: pickup.trim());
  }

  void setPickupCoords(double lat, double lng) {
    state = state.copyWith(pickupLat: lat, pickupLng: lng);
  }

  void setPickupWithCoords(String pickup, {required double lat, required double lng}) {
    state = state.copyWith(
      puntoRecojo: pickup.trim(),
      pickupLat: lat,
      pickupLng: lng,
    );
  }

  void markPaid({required String reservaId}) {
    state = state.copyWith(reservaId: reservaId);
  }

  /// Restaura el estado local desde una reserva activa en Supabase (home / realtime).
  void hydrateFromActiveReservation(Map<String, dynamic> row) {
    final tripRaw = row['trips'];
    final trip = tripRaw is Map<String, dynamic>
        ? tripRaw
        : tripRaw is Map
            ? tripRaw.cast<String, dynamic>()
            : null;
    if (trip == null) return;

    final driverRaw = trip['drivers'];
    final driverMap = driverRaw is Map<String, dynamic>
        ? driverRaw
        : driverRaw is Map
            ? driverRaw.cast<String, dynamic>()
            : null;
    if (driverMap == null) return;

    final profileRaw = driverMap['profiles'];
    final profile = profileRaw is Map<String, dynamic>
        ? profileRaw
        : profileRaw is Map
            ? profileRaw.cast<String, dynamic>()
            : null;

    final routeRaw = trip['routes'];
    final route = routeRaw is Map<String, dynamic>
        ? routeRaw
        : routeRaw is Map
            ? routeRaw.cast<String, dynamic>()
            : null;

    final from = route?['from_label']?.toString().trim() ?? '';
    final to = route?['to_label']?.toString().trim() ?? '';
    final routeLabel = (from.isNotEmpty && to.isNotEmpty) ? '$from → $to' : (route?['name']?.toString() ?? 'Ruta');

    final driverName = profile?['name']?.toString().trim();
    final seats = <int>[];
    final seatsRaw = row['seats'];
    if (seatsRaw is List) {
      for (final s in seatsRaw) {
        final parsed = s is int ? s : int.tryParse(s.toString());
        if (parsed != null) seats.add(parsed);
      }
    }
    seats.sort();

    state = state.copyWith(
      reservaId: row['id']?.toString(),
      conductorSeleccionado: ReservaDriverInfo(
        tripId: trip['id']?.toString() ?? '',
        driverId: driverMap['id']?.toString() ?? '',
        name: (driverName != null && driverName.isNotEmpty) ? driverName : 'Conductor',
        plate: driverMap['plate']?.toString() ?? '—',
        vehicleType: '',
        totalSeats: 0,
        routeLabel: routeLabel,
        rating: 0,
        ratingCount: 0,
        status: trip['status']?.toString() ?? 'esperando',
      ),
      asientosSeleccionados: seats,
      puntoRecojo: row['pickup_point']?.toString(),
    );
  }

  void requestAdditionalCharge(double amount) {
    state = state.copyWith(additionalChargePending: true, additionalChargeAmount: amount);
  }

  void clearAdditionalCharge() {
    state = state.copyWith(clearAdditionalCharge: true);
  }

  void setVehiculoPartio(bool value) {
    state = state.copyWith(vehiculoPartio: value);
  }

  void reset() {
    state = ReservaState.empty;
  }
}

final reservaProvider = StateNotifierProvider<ReservaController, ReservaState>(
  (ref) => ReservaController(),
);

/// Asientos ocupados en Supabase (`reservations` activas + completadas para el `trip_id`).
final occupiedSeatsByTripProvider = FutureProvider.autoDispose.family<List<int>, String>(
  (ref, tripId) async {
    try {
      if (tripId.trim().isEmpty) return const <int>[];

      final rows = await Supabase.instance.client
          .from('reservations')
          .select('seats')
          .eq('trip_id', tripId)
          .inFilter('status', ['activa', 'completada']);

      final seats = <int>{};
      for (final rm in (rows as List).cast<Map<String, dynamic>>()) {
        final raw = rm['seats'];
        if (raw is! List) continue;
        for (final s in raw) {
          final n = s is int ? s : (s is num ? s.toInt() : int.tryParse('$s'));
          if (n != null) seats.add(n);
        }
      }
      final out = seats.toList()..sort();
      return out;
    } catch (_) {
      return const <int>[];
    }
  },
);
