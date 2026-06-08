import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_data.dart';

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

class ReservaState {
  const ReservaState({
    required this.reservaId,
    required this.conductorSeleccionado,
    required this.asientosSeleccionados,
    required this.acompanantes,
    required this.puntoRecojo,
    required this.vehiculoPartio,
    required this.additionalChargePending,
    required this.additionalChargeAmount,
  });

  final String? reservaId;
  final MockDriver? conductorSeleccionado;
  final List<int> asientosSeleccionados;
  final Map<int, ReservaAcompanante> acompanantes;
  final String? puntoRecojo;
  final bool vehiculoPartio;
  final bool additionalChargePending;
  final double additionalChargeAmount;

  double get montoTotal => asientosSeleccionados.length * 15.0;
  double get montoTotalFinal => montoTotal + (additionalChargePending ? additionalChargeAmount : 0.0);

  ReservaState copyWith({
    String? reservaId,
    MockDriver? conductorSeleccionado,
    List<int>? asientosSeleccionados,
    Map<int, ReservaAcompanante>? acompanantes,
    String? puntoRecojo,
    bool clearPickup = false,
    bool? vehiculoPartio,
    bool? additionalChargePending,
    double? additionalChargeAmount,
    bool clearAdditionalCharge = false,
  }) {
    return ReservaState(
      reservaId: reservaId ?? this.reservaId,
      conductorSeleccionado: conductorSeleccionado ?? this.conductorSeleccionado,
      asientosSeleccionados: asientosSeleccionados ?? this.asientosSeleccionados,
      acompanantes: acompanantes ?? this.acompanantes,
      puntoRecojo: clearPickup ? null : (puntoRecojo ?? this.puntoRecojo),
      vehiculoPartio: vehiculoPartio ?? this.vehiculoPartio,
      additionalChargePending: clearAdditionalCharge
          ? false
          : (additionalChargePending ?? this.additionalChargePending),
      additionalChargeAmount:
          clearAdditionalCharge ? 0.0 : (additionalChargeAmount ?? this.additionalChargeAmount),
    );
  }

  static const empty = ReservaState(
    reservaId: null,
    conductorSeleccionado: null,
    asientosSeleccionados: <int>[],
    acompanantes: <int, ReservaAcompanante>{},
    puntoRecojo: null,
    vehiculoPartio: false,
    additionalChargePending: false,
    additionalChargeAmount: 0.0,
  );
}

class ReservaController extends StateNotifier<ReservaState> {
  ReservaController() : super(ReservaState.empty);

  void startWithDriver(MockDriver driver) {
    state = ReservaState(
      reservaId: null,
      conductorSeleccionado: driver,
      asientosSeleccionados: const <int>[],
      acompanantes: const <int, ReservaAcompanante>{},
      puntoRecojo: null,
      vehiculoPartio: false,
      additionalChargePending: false,
      additionalChargeAmount: 0.0,
    );
  }

  void setSelectedSeats(List<int> seats) {
    final normalized = seats.toSet().toList()..sort();
    final keep = <int, ReservaAcompanante>{};
    for (final s in normalized) {
      final existing = state.acompanantes[s];
      if (existing != null) keep[s] = existing;
    }
    state = state.copyWith(
      asientosSeleccionados: normalized,
      acompanantes: keep,
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

  void markPaid({required String reservaId}) {
    state = state.copyWith(reservaId: reservaId);
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

final occupiedSeatsByPlateProvider = FutureProvider.autoDispose.family<List<int>, String>(
  (ref, plate) async {
    try {
      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('plate', plate)
          .maybeSingle();
      final driverId = driver?['id']?.toString();
      if (driverId == null) return const <int>[];

      final trip = await Supabase.instance.client
          .from('trips')
          .select('id, status')
          .eq('driver_id', driverId)
          .neq('status', 'completado')
          .neq('status', 'cancelado')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final tripId = trip?['id']?.toString();
      if (tripId == null) return const <int>[];

      final rows = await Supabase.instance.client
          .from('reservations')
          .select('seats')
          .eq('trip_id', tripId)
          .eq('status', 'activa');

      final seats = <int>{};
      for (final rm in (rows as List).cast<Map<String, dynamic>>()) {
        final raw = rm['seats'];
        if (raw is! List) continue;
        for (final s in raw) {
          if (s is int) seats.add(s);
        }
      }
      final out = seats.toList()..sort();
      return out;
    } catch (_) {
      return const <int>[];
    }
  },
);
