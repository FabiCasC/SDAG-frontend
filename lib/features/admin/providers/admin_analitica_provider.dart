import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AdminAnaliticaPeriodo {
  hoy,
  semana,
  mes,
  custom,
}

class AdminAnaliticaState {
  const AdminAnaliticaState({
    required this.periodoSeleccionado,
    required this.estadisticas,
    required this.ingresosDiarios,
    required this.rankingConductores,
    required this.filtroFechaDesde,
    required this.filtroFechaHasta,
  });

  final AdminAnaliticaPeriodo periodoSeleccionado;
  final AdminAnaliticaStats estadisticas;
  final List<AdminIngresoDiario> ingresosDiarios;
  final List<AdminRankingConductor> rankingConductores;
  final DateTime? filtroFechaDesde;
  final DateTime? filtroFechaHasta;

  AdminAnaliticaState copyWith({
    AdminAnaliticaPeriodo? periodoSeleccionado,
    AdminAnaliticaStats? estadisticas,
    List<AdminIngresoDiario>? ingresosDiarios,
    List<AdminRankingConductor>? rankingConductores,
    DateTime? filtroFechaDesde,
    DateTime? filtroFechaHasta,
  }) {
    return AdminAnaliticaState(
      periodoSeleccionado: periodoSeleccionado ?? this.periodoSeleccionado,
      estadisticas: estadisticas ?? this.estadisticas,
      ingresosDiarios: ingresosDiarios ?? this.ingresosDiarios,
      rankingConductores: rankingConductores ?? this.rankingConductores,
      filtroFechaDesde: filtroFechaDesde ?? this.filtroFechaDesde,
      filtroFechaHasta: filtroFechaHasta ?? this.filtroFechaHasta,
    );
  }

  static AdminAnaliticaState initial() => const AdminAnaliticaState(
        periodoSeleccionado: AdminAnaliticaPeriodo.mes,
        estadisticas: AdminAnaliticaStats.zero,
        ingresosDiarios: [],
        rankingConductores: [],
        filtroFechaDesde: null,
        filtroFechaHasta: null,
      );
}

class AdminAnaliticaStats {
  const AdminAnaliticaStats({
    required this.ingresosTotales,
    required this.viajesCompletados,
    required this.ocupacionPromedio,
    required this.comisionesPagadas,
  });

  final double ingresosTotales;
  final int viajesCompletados;
  final double ocupacionPromedio;
  final double comisionesPagadas;

  static const zero = AdminAnaliticaStats(
    ingresosTotales: 0,
    viajesCompletados: 0,
    ocupacionPromedio: 0,
    comisionesPagadas: 0,
  );
}

class AdminIngresoDiario {
  const AdminIngresoDiario({
    required this.label,
    required this.monto,
  });

  final String label;
  final double monto;
}

class AdminRankingConductor {
  const AdminRankingConductor({
    required this.conductorId,
    required this.nombre,
    required this.placa,
    required this.ocupacion,
    required this.recaudado,
    required this.comision,
    required this.viajes,
    required this.asientos,
  });

  final String conductorId;
  final String nombre;
  final String placa;
  final double ocupacion;
  final double recaudado;
  final double comision;
  final int viajes;
  final int asientos;
}

class AdminAnaliticaController extends StateNotifier<AdminAnaliticaState> {
  AdminAnaliticaController({required this.ref}) : super(AdminAnaliticaState.initial()) {
    cargarEstadisticas();
  }

  final Ref ref;

  void filtrarPorPeriodo(AdminAnaliticaPeriodo periodo, {DateTime? desde, DateTime? hasta}) {
    state = state.copyWith(
      periodoSeleccionado: periodo,
      filtroFechaDesde: periodo == AdminAnaliticaPeriodo.custom ? desde : null,
      filtroFechaHasta: periodo == AdminAnaliticaPeriodo.custom ? hasta : null,
    );
    cargarEstadisticas();
  }

  Future<void> cargarEstadisticas() async {
    final now = DateTime.now();
    final (from, to) = _rangeForPeriod(
      state.periodoSeleccionado,
      now,
      state.filtroFechaDesde,
      state.filtroFechaHasta,
    );
    final fromIso = DateTime(from.year, from.month, from.day).toIso8601String();
    final toIso = DateTime(to.year, to.month, to.day).add(const Duration(days: 1)).toIso8601String();

    try {
      final trips = await Supabase.instance.client
          .from('trips')
          .select('id, driver_id, amount, created_at, status')
          .gte('created_at', fromIso)
          .lt('created_at', toIso);

      final completed = <Map<String, dynamic>>[];
      for (final tm in (trips as List).cast<Map<String, dynamic>>()) {
        if (tm['status']?.toString() != 'completado') continue;
        completed.add(tm);
      }

      final tripIds = completed.map((e) => e['id']?.toString()).whereType<String>().toList();
      final driverIds = completed.map((e) => e['driver_id']?.toString()).whereType<String>().toSet().toList();

      final ingresosTotales = completed.fold<double>(
        0,
        (sum, t) => sum + (((t['amount'] as num?)?.toDouble()) ?? 0.0),
      );

      final payouts = await Supabase.instance.client
          .from('driver_payouts')
          .select('commission_amount, created_at')
          .gte('created_at', fromIso)
          .lt('created_at', toIso);
      var comisionesPagadas = 0.0;
      for (final pm in (payouts as List).cast<Map<String, dynamic>>()) {
          comisionesPagadas += ((pm['commission_amount'] as num?)?.toDouble()) ?? 0.0;
      }

      final ingresosPorDia = <String, double>{};
      for (final t in completed) {
        final createdAt = DateTime.tryParse(t['created_at']?.toString() ?? '');
        if (createdAt == null) continue;
        final key = '${createdAt.day}/${createdAt.month}';
        ingresosPorDia[key] = (ingresosPorDia[key] ?? 0.0) + (((t['amount'] as num?)?.toDouble()) ?? 0.0);
      }
      final ingresosDiarios = ingresosPorDia.entries
          .map((e) => AdminIngresoDiario(label: e.key, monto: e.value))
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));

      final seatsByTrip = <String, int>{};
      if (tripIds.isNotEmpty) {
        final reservations = await Supabase.instance.client
            .from('reservations')
            .select('trip_id, seats')
            .inFilter('trip_id', tripIds);
        for (final rm in (reservations as List).cast<Map<String, dynamic>>()) {
            final tripId = rm['trip_id']?.toString();
            final seats = rm['seats'];
            if (tripId == null || seats is! List) continue;
            seatsByTrip[tripId] = (seatsByTrip[tripId] ?? 0) + seats.length;
        }
      }

      final drivers = <String, Map<String, dynamic>>{};
      if (driverIds.isNotEmpty) {
        final driverRows = await Supabase.instance.client
            .from('drivers')
            .select('id, profile_id, plate, capacity, commission_pct')
            .inFilter('id', driverIds);
        for (final dm in (driverRows as List).cast<Map<String, dynamic>>()) {
          final id = dm['id']?.toString();
          if (id != null) drivers[id] = dm;
        }
      }

      final profileIds = drivers.values.map((d) => d['profile_id']?.toString()).whereType<String>().toSet().toList();
      final profiles = <String, Map<String, dynamic>>{};
      if (profileIds.isNotEmpty) {
        final profileRows = await Supabase.instance.client.from('profiles').select('id, name').inFilter('id', profileIds);
        for (final pm in (profileRows as List).cast<Map<String, dynamic>>()) {
          final id = pm['id']?.toString();
          if (id != null) profiles[id] = pm;
        }
      }

      final rankingAgg = <String, _DriverAgg>{};
      for (final t in completed) {
        final driverId = t['driver_id']?.toString();
        final tripId = t['id']?.toString();
        if (driverId == null || tripId == null) continue;
        final amount = ((t['amount'] as num?)?.toDouble()) ?? 0.0;
        final seats = seatsByTrip[tripId] ?? 0;
        rankingAgg.putIfAbsent(driverId, () => _DriverAgg()).add(amount: amount, seats: seats);
      }

      final ranking = <AdminRankingConductor>[];
      for (final entry in rankingAgg.entries) {
        final driverId = entry.key;
        final agg = entry.value;
        final d = drivers[driverId];
        final plate = d?['plate']?.toString() ?? '—';
        final cap = (d?['capacity'] as int?) ?? 8;
        final pct = ((d?['commission_pct'] as num?)?.toDouble()) ?? 15.0;
        final profileId = d?['profile_id']?.toString();
        final name = profileId == null ? driverId : (profiles[profileId]?['name']?.toString() ?? driverId);
        final ocupacion = agg.viajes == 0 || cap <= 0 ? 0.0 : (agg.asientos / (agg.viajes * cap)).clamp(0.0, 1.0).toDouble();
        ranking.add(
          AdminRankingConductor(
            conductorId: driverId,
            nombre: name,
            placa: plate,
            ocupacion: ocupacion,
            recaudado: agg.recaudado,
            comision: agg.recaudado * (pct / 100.0),
            viajes: agg.viajes,
            asientos: agg.asientos,
          ),
        );
      }
      ranking.sort((a, b) => b.recaudado.compareTo(a.recaudado));

      final avgOcc = ranking.isEmpty
          ? 0.0
          : ranking.fold<double>(0.0, (sum, r) => sum + r.ocupacion) / ranking.length;

      state = state.copyWith(
        estadisticas: AdminAnaliticaStats(
          ingresosTotales: ingresosTotales,
          viajesCompletados: completed.length,
          ocupacionPromedio: avgOcc,
          comisionesPagadas: comisionesPagadas,
        ),
        ingresosDiarios: ingresosDiarios,
        rankingConductores: ranking,
      );
    } catch (_) {
      state = state.copyWith(
        estadisticas: AdminAnaliticaStats.zero,
        ingresosDiarios: const [],
        rankingConductores: const [],
      );
    }
  }

  Future<void> exportarReporte() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
  }

  (DateTime, DateTime) _rangeForPeriod(
    AdminAnaliticaPeriodo periodo,
    DateTime now,
    DateTime? customFrom,
    DateTime? customTo,
  ) {
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (periodo) {
      case AdminAnaliticaPeriodo.hoy:
        return (todayStart, todayStart);
      case AdminAnaliticaPeriodo.semana:
        return (todayStart.subtract(const Duration(days: 6)), todayStart);
      case AdminAnaliticaPeriodo.mes:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
      case AdminAnaliticaPeriodo.custom:
        final from = customFrom ?? todayStart.subtract(const Duration(days: 6));
        final to = customTo ?? todayStart;
        return (from, to);
    }
  }
}

final adminAnaliticaProvider =
    StateNotifierProvider<AdminAnaliticaController, AdminAnaliticaState>(
  (ref) => AdminAnaliticaController(ref: ref),
);

class _DriverAgg {
  double recaudado = 0.0;
  int viajes = 0;
  int asientos = 0;

  void add({required double amount, required int seats}) {
    recaudado += amount;
    viajes += 1;
    asientos += seats;
  }
}
