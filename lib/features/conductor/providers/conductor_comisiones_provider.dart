import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/comision.dart';

enum ConductorEstadoSolicitudPago {
  sinSolicitud,
  pendiente,
  confirmadoAdmin,
  recibidoConductor,
}

class ConductorViajeDiaItem {
  const ConductorViajeDiaItem({
    required this.id,
    required this.horaLabel,
    required this.rutaLabel,
    required this.ocupados,
    required this.capacidad,
  });

  final String id;
  final String horaLabel;
  final String rutaLabel;
  final int ocupados;
  final int capacidad;

  double get totalRecaudado => ocupados * 15.0;
}

class ConductorComisionesState {
  const ConductorComisionesState({
    required this.hoy,
    required this.porcentajeComision,
    required this.viajesHoy,
    required this.estadoSolicitud,
    required this.historialPagos,
    required this.solicitudAt,
  });

  final DateTime hoy;
  final double porcentajeComision;
  final List<ConductorViajeDiaItem> viajesHoy;
  final ConductorEstadoSolicitudPago estadoSolicitud;
  final List<Comision> historialPagos;
  final DateTime? solicitudAt;

  double get totalDia => viajesHoy.fold(0.0, (sum, v) => sum + v.totalRecaudado);
  double get comisionDia => totalDia * porcentajeComision;
  int get viajesCompletadosHoy => viajesHoy.length;

  double get totalMes {
    return historialPagos
        .where((c) => c.fecha.year == hoy.year && c.fecha.month == hoy.month)
        .fold(0.0, (sum, c) => sum + c.comision);
  }

  ConductorComisionesState copyWith({
    DateTime? hoy,
    double? porcentajeComision,
    List<ConductorViajeDiaItem>? viajesHoy,
    ConductorEstadoSolicitudPago? estadoSolicitud,
    List<Comision>? historialPagos,
    DateTime? solicitudAt,
    bool clearSolicitudAt = false,
  }) {
    return ConductorComisionesState(
      hoy: hoy ?? this.hoy,
      porcentajeComision: porcentajeComision ?? this.porcentajeComision,
      viajesHoy: viajesHoy ?? this.viajesHoy,
      estadoSolicitud: estadoSolicitud ?? this.estadoSolicitud,
      historialPagos: historialPagos ?? this.historialPagos,
      solicitudAt: clearSolicitudAt ? null : (solicitudAt ?? this.solicitudAt),
    );
  }
}

class ConductorComisionesController extends StateNotifier<ConductorComisionesState> {
  ConductorComisionesController()
      : super(
          ConductorComisionesState(
            hoy: DateTime.now(),
            porcentajeComision: 0.15,
            viajesHoy: const [],
            estadoSolicitud: ConductorEstadoSolicitudPago.sinSolicitud,
            historialPagos: const [],
            solicitudAt: null,
          ),
        ) {
    _load();
  }

  static const _estadoKey = 'sdag_conductor_pago_estado_solicitud';
  static const _solicitudAtKey = 'sdag_conductor_pago_solicitud_at';
  static const _historialExtraKey = 'sdag_conductor_pago_historial_extra';

  Timer? _autoConfirmTimer;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEstado = prefs.getString(_estadoKey);
    final estado = _estadoFromString(rawEstado) ?? ConductorEstadoSolicitudPago.sinSolicitud;
    final solicitudAt = DateTime.tryParse(prefs.getString(_solicitudAtKey) ?? '');

    final extraRaw = prefs.getString(_historialExtraKey);
    final extra = _decodeComisiones(extraRaw);

    var next = state.copyWith(
      estadoSolicitud: estado,
      solicitudAt: solicitudAt,
      historialPagos: [...extra, ...state.historialPagos],
    );

    if (estado == ConductorEstadoSolicitudPago.pendiente && solicitudAt != null) {
      final elapsed = DateTime.now().difference(solicitudAt);
      if (elapsed.inSeconds >= 4) {
        next = next.copyWith(estadoSolicitud: ConductorEstadoSolicitudPago.confirmadoAdmin);
      } else {
        _autoConfirmTimer?.cancel();
        _autoConfirmTimer = Timer(Duration(seconds: 4 - elapsed.inSeconds), () {
          if (mounted) {
            state = state.copyWith(estadoSolicitud: ConductorEstadoSolicitudPago.confirmadoAdmin);
            _persistEstado();
          }
        });
      }
    }

    state = next;
    await _persistEstado();

    await _syncFromSupabase();
  }

  Future<void> _syncFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final driver = await Supabase.instance.client.from('drivers').select('id, commission_pct, capacity').eq('profile_id', user.id).maybeSingle();
      final commissionPct = (driver?['commission_pct'] as num?)?.toDouble();
      final capacity = (driver?['capacity'] as int?) ?? 8;
      final driverId = driver?['id']?.toString();

      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(const Duration(days: 1));

      final viajes = <ConductorViajeDiaItem>[];
      if (driverId != null) {
        final trips = await Supabase.instance.client
            .from('trips')
            .select('id, created_at, route_id')
            .eq('driver_id', driverId)
            .gte('created_at', start.toIso8601String())
            .lt('created_at', end.toIso8601String())
            .order('created_at', ascending: true);

        for (final m in (trips as List).cast<Map<String, dynamic>>()) {
          final tripId = m['id']?.toString();
          final createdAt = DateTime.tryParse(m['created_at']?.toString() ?? '');
            if (tripId == null || createdAt == null) continue;

            final reservations = await Supabase.instance.client
                .from('reservations')
                .select('seats')
                .eq('trip_id', tripId)
                .eq('status', 'activa');
            var ocupados = 0;
            for (final rm in (reservations as List).cast<Map<String, dynamic>>()) {
              final seats = rm['seats'];
              if (seats is List) ocupados += seats.length;
            }

            final routeId = m['route_id']?.toString();
            String rutaLabel = 'Ruta';
            if (routeId != null) {
              final route = await Supabase.instance.client.from('routes').select('name').eq('id', routeId).maybeSingle();
              rutaLabel = route?['name']?.toString() ?? rutaLabel;
            }

            final hh = createdAt.hour;
            final mm = createdAt.minute.toString().padLeft(2, '0');
            final suffix = hh >= 12 ? 'PM' : 'AM';
            final hh12 = ((hh + 11) % 12) + 1;
            final horaLabel = '$hh12:$mm $suffix';

            viajes.add(
              ConductorViajeDiaItem(
                id: tripId,
                horaLabel: horaLabel,
                rutaLabel: rutaLabel,
                ocupados: ocupados,
                capacidad: capacity,
              ),
            );
        }
      }

      final payouts = await Supabase.instance.client
          .from('driver_payouts')
          .select('id, created_at, gross_amount, commission_amount, status')
          .eq('profile_id', user.id)
          .order('created_at', ascending: false);
      final historial = <Comision>[];
      for (final pm in (payouts as List).cast<Map<String, dynamic>>()) {
        final id = pm['id']?.toString();
        final createdAt = DateTime.tryParse(pm['created_at']?.toString() ?? '');
        final recaudado = (pm['gross_amount'] as num?)?.toDouble();
        final comision = (pm['commission_amount'] as num?)?.toDouble();
        final status = pm['status']?.toString();
        if (id == null || createdAt == null || recaudado == null || comision == null || status == null) continue;
        historial.add(
          Comision(
            id: id,
            fecha: DateTime(createdAt.year, createdAt.month, createdAt.day),
            recaudado: recaudado,
            comision: comision,
            estado: status,
          ),
        );
      }

      final req = await Supabase.instance.client
          .from('driver_payout_requests')
          .select('status, created_at')
          .eq('profile_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final status = req?['status']?.toString();
      final reqAt = DateTime.tryParse(req?['created_at']?.toString() ?? '');
      final estadoSolicitud = switch (status) {
        'pendiente' => ConductorEstadoSolicitudPago.pendiente,
        'confirmado_admin' => ConductorEstadoSolicitudPago.confirmadoAdmin,
        'recibido_conductor' => ConductorEstadoSolicitudPago.recibidoConductor,
        _ => ConductorEstadoSolicitudPago.sinSolicitud,
      };

      state = state.copyWith(
        porcentajeComision: (commissionPct ?? 15.0) / 100.0,
        viajesHoy: viajes,
        historialPagos: historial,
        estadoSolicitud: estadoSolicitud,
        solicitudAt: reqAt,
      );
    } catch (_) {}
  }

  ConductorEstadoSolicitudPago? _estadoFromString(String? raw) {
    if (raw == null) return null;
    for (final e in ConductorEstadoSolicitudPago.values) {
      if (e.name == raw) return e;
    }
    return null;
  }

  Future<void> _persistEstado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_estadoKey, state.estadoSolicitud.name);
    if (state.solicitudAt != null) {
      await prefs.setString(_solicitudAtKey, state.solicitudAt!.toIso8601String());
    } else {
      await prefs.remove(_solicitudAtKey);
    }
  }

  List<Comision> _decodeComisiones(String? raw) {
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <Comision>[];
      for (final item in decoded) {
        if (item is Map) {
          final m = item.cast<String, dynamic>();
          final id = m['id'] as String?;
          final fecha = DateTime.tryParse(m['fecha'] as String? ?? '');
          final recaudado = (m['recaudado'] as num?)?.toDouble();
          final comision = (m['comision'] as num?)?.toDouble();
          final estado = m['estado'] as String?;
          if (id == null || fecha == null || recaudado == null || comision == null || estado == null) continue;
          out.add(Comision(id: id, fecha: fecha, recaudado: recaudado, comision: comision, estado: estado));
        }
      }
      out.sort((a, b) => b.fecha.compareTo(a.fecha));
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _appendHistorialExtra(Comision c) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _decodeComisiones(prefs.getString(_historialExtraKey));
    final next = [c, ...existing];
    final raw = jsonEncode(
      next
          .map((e) => {
                'id': e.id,
                'fecha': e.fecha.toIso8601String(),
                'recaudado': e.recaudado,
                'comision': e.comision,
                'estado': e.estado,
              })
          .toList(),
    );
    await prefs.setString(_historialExtraKey, raw);
  }

  Future<void> solicitarPago() async {
    if (state.estadoSolicitud != ConductorEstadoSolicitudPago.sinSolicitud) return;
    final now = DateTime.now();
    state = state.copyWith(
      estadoSolicitud: ConductorEstadoSolicitudPago.pendiente,
      solicitudAt: now,
    );
    await _persistEstado();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('driver_payout_requests').insert({
          'profile_id': user.id,
          'status': 'pendiente',
          'gross_amount': state.totalDia,
          'commission_amount': state.comisionDia,
          'created_at': now.toIso8601String(),
        });
      } catch (_) {}
    }
    _autoConfirmTimer?.cancel();
    _autoConfirmTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      state = state.copyWith(estadoSolicitud: ConductorEstadoSolicitudPago.confirmadoAdmin);
      _persistEstado();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        Supabase.instance.client
            .from('driver_payout_requests')
            .update({'status': 'confirmado_admin'})
            .eq('profile_id', user.id)
            .eq('status', 'pendiente');
      }
    });
  }

  Future<void> confirmarRecepcion() async {
    if (state.estadoSolicitud != ConductorEstadoSolicitudPago.confirmadoAdmin) return;
    final now = DateTime.now();
    final user = Supabase.instance.client.auth.currentUser;
    String payoutId = 'p_${now.microsecondsSinceEpoch}';
    if (user != null) {
      try {
        final row = await Supabase.instance.client.from('driver_payouts').insert({
          'profile_id': user.id,
          'gross_amount': state.totalDia,
          'commission_amount': state.comisionDia,
          'status': 'Confirmado',
          'created_at': now.toIso8601String(),
        }).select('id').single();
        payoutId = row['id']?.toString() ?? payoutId;
      } catch (_) {}

      try {
        await Supabase.instance.client
            .from('driver_payout_requests')
            .update({'status': 'recibido_conductor'})
            .eq('profile_id', user.id)
            .eq('status', 'confirmado_admin');
      } catch (_) {}
    }

    final c = Comision(
      id: payoutId,
      fecha: DateTime(now.year, now.month, now.day),
      recaudado: state.totalDia,
      comision: state.comisionDia,
      estado: 'Confirmado',
    );
    state = state.copyWith(
      estadoSolicitud: ConductorEstadoSolicitudPago.recibidoConductor,
      historialPagos: [c, ...state.historialPagos],
      clearSolicitudAt: true,
    );
    await _appendHistorialExtra(c);
    await _persistEstado();
  }

  @override
  void dispose() {
    _autoConfirmTimer?.cancel();
    super.dispose();
  }
}

final conductorComisionesProvider =
    StateNotifierProvider<ConductorComisionesController, ConductorComisionesState>(
  (ref) => ConductorComisionesController(),
);
