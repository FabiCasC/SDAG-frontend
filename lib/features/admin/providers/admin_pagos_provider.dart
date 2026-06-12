import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_conductores_provider.dart';
import 'admin_conductores_provider.dart';
class AdminPagosState {
  const AdminPagosState({
    required this.solicitudesPendientes,
    required this.historialPagos,
    required this.filtroConductor,
    required this.filtroFechaDesde,
    required this.filtroFechaHasta,
    required this.banner,
  });

  final List<AdminPagoSolicitud> solicitudesPendientes;
  final List<AdminPagoHistorial> historialPagos;
  final String? filtroConductor;
  final DateTime? filtroFechaDesde;
  final DateTime? filtroFechaHasta;
  final AdminPagoBanner? banner;

  AdminPagosState copyWith({
    List<AdminPagoSolicitud>? solicitudesPendientes,
    List<AdminPagoHistorial>? historialPagos,
    String? filtroConductor,
    DateTime? filtroFechaDesde,
    DateTime? filtroFechaHasta,
    AdminPagoBanner? banner,
    bool clearBanner = false,
  }) {
    return AdminPagosState(
      solicitudesPendientes: solicitudesPendientes ?? this.solicitudesPendientes,
      historialPagos: historialPagos ?? this.historialPagos,
      filtroConductor: filtroConductor ?? this.filtroConductor,
      filtroFechaDesde: filtroFechaDesde ?? this.filtroFechaDesde,
      filtroFechaHasta: filtroFechaHasta ?? this.filtroFechaHasta,
      banner: clearBanner ? null : (banner ?? this.banner),
    );
  }

  List<AdminPagoHistorial> get historialFiltrado {
    final conductor = filtroConductor;
    final from = filtroFechaDesde;
    final to = filtroFechaHasta;
    final out = <AdminPagoHistorial>[];
    for (final p in historialPagos) {
      if (conductor != null && p.conductor != conductor) continue;
      if (from != null && p.confirmadoAt.isBefore(from)) continue;
      if (to != null && p.confirmadoAt.isAfter(to)) continue;
      out.add(p);
    }
    out.sort((a, b) => b.confirmadoAt.compareTo(a.confirmadoAt));
    return out;
  }

  static AdminPagosState initial(Ref ref) {
    return AdminPagosState(
      solicitudesPendientes: const [],
      historialPagos: const [],
      filtroConductor: null,
      filtroFechaDesde: null,
      filtroFechaHasta: null,
      banner: null,
    );
  }
}

class AdminPagosController extends StateNotifier<AdminPagosState> {
  AdminPagosController({required this.ref}) : super(AdminPagosState.initial(ref)) {
    _loadFromSupabase();
  }

  final Ref ref;

  Future<void> _loadFromSupabase() async {
    try {
      final requests = await Supabase.instance.client
          .from('driver_payout_requests')
          .select('id, profile_id, gross_amount, commission_amount, status, created_at')
          .order('created_at', ascending: false);
      final payouts = await Supabase.instance.client
          .from('driver_payouts')
          .select('id, profile_id, gross_amount, commission_amount, status, created_at')
          .order('created_at', ascending: false);

      final byProfile = <String, Map<String, dynamic>>{};
      for (final c in ref.read(adminConductoresProvider).listaConductores) {
        final id = c['id']?.toString();
        if (id != null) byProfile[id] = c;
      }

      final solicitudes = <AdminPagoSolicitud>[];
      for (final rm in (requests as List).cast<Map<String, dynamic>>()) {
          final id = rm['id']?.toString();
          final profileId = rm['profile_id']?.toString();
          final status = rm['status']?.toString();
          final createdAt = DateTime.tryParse(rm['created_at']?.toString() ?? '');
          final monto = (rm['commission_amount'] as num?)?.toDouble();
          final total = (rm['gross_amount'] as num?)?.toDouble();
          if (id == null || profileId == null || createdAt == null || monto == null || total == null) continue;
          if (status != 'pendiente') continue;
          final c = byProfile[profileId];
          final nombre = c != null ? '${c['nombres'] ?? ''} ${c['apellidos'] ?? ''}'.trim() : profileId;
          
          solicitudes.add(
            AdminPagoSolicitud(
              id: id,
              profileId: profileId,
              conductor: nombre.isEmpty ? profileId : nombre,
              placa: c?['placa']?.toString() ?? '—',
              monto: monto,
              porcentaje: (c?['comisionPorcentaje'] as num?)?.toDouble() ?? 15.0,
              totalRecaudado: total,
              solicitadoAt: createdAt,
              detalleViajes: await _fetchDetalleViajes(c?['driverRecordId']?.toString() ?? '', createdAt),
            ),
          );
      }

      final historial = <AdminPagoHistorial>[];
      for (final pm in (payouts as List).cast<Map<String, dynamic>>()) {
          final id = pm['id']?.toString();
          final profileId = pm['profile_id']?.toString();
          final createdAt = DateTime.tryParse(pm['created_at']?.toString() ?? '');
          final monto = (pm['commission_amount'] as num?)?.toDouble();
          final total = (pm['gross_amount'] as num?)?.toDouble();
          final estado = pm['status']?.toString() ?? '—';
          if (id == null || profileId == null || createdAt == null || monto == null || total == null) continue;
          final c = byProfile[profileId];
          final nombre = c != null ? '${c['nombres'] ?? ''} ${c['apellidos'] ?? ''}'.trim() : profileId;
          
          historial.add(
            AdminPagoHistorial(
              id: id,
              conductor: nombre.isEmpty ? profileId : nombre,
              placa: c?['placa']?.toString() ?? '—',
              monto: monto,
              porcentaje: (c?['comisionPorcentaje'] as num?)?.toDouble() ?? 15.0,
              totalRecaudado: total,
              confirmadoAt: createdAt,
              estado: estado,
              detalleViajes: await _fetchDetalleViajes(c?['driverRecordId']?.toString() ?? '', createdAt),
            ),
          );
      }

      state = state.copyWith(
        solicitudesPendientes: solicitudes,
        historialPagos: historial,
      );
    } catch (_) {}
  }

  Future<void> confirmarPago(String solicitudId) async {
    final idx = state.solicitudesPendientes.indexWhere((e) => e.id == solicitudId);
    if (idx < 0) return;
    final req = state.solicitudesPendientes[idx];
    try {
      await Supabase.instance.client
          .from('driver_payout_requests')
          .update({'status': 'completado'})
          .eq('id', solicitudId);
          
      await Supabase.instance.client.from('driver_payouts').insert({
        'profile_id': req.profileId,
        'gross_amount': req.totalRecaudado,
        'commission_amount': req.monto,
        'status': 'Confirmado',
      });

      await Supabase.instance.client.from('drivers').update({
        'last_pago_confirmado_at': DateTime.now().toUtc().toIso8601String(),
        'pago_confirmado': true,
        'estado': 'disponible'
      }).eq('profile_id', req.profileId);

      await _loadFromSupabase();
      ref.read(adminConductoresProvider.notifier).refresh();
    } catch (_) {}
  }

  void filtrarHistorial({
    String? filtroConductor,
    DateTime? filtroFechaDesde,
    DateTime? filtroFechaHasta,
  }) {
    state = state.copyWith(
      filtroConductor: filtroConductor,
      filtroFechaDesde: filtroFechaDesde,
      filtroFechaHasta: filtroFechaHasta,
    );
  }

  Future<AdminPagoSolicitud?> simularNuevaSolicitud() async {
    final now = DateTime.now();
    final conductores = ref.read(adminConductoresProvider).listaConductores;
    final selected = conductores.isEmpty ? null : conductores.first;
    if (selected == null) return null;

    final profileId = selected['id']?.toString();
    final driverRecordId = selected['driverRecordId']?.toString();
    if (profileId == null || driverRecordId == null) return null;

    final porcentaje = (selected['comisionPorcentaje'] as double?) ?? 15.0;
    
    // Fetch real trips to calculate total
    final detalleViajes = await _fetchDetalleViajes(driverRecordId, now);
    final total = detalleViajes.fold<double>(0, (sum, item) => sum + item.monto);
    if (total <= 0) return null; // No hay viajes para cobrar

    final monto = (total * porcentaje / 100);
    try {
      final row = await Supabase.instance.client.from('driver_payout_requests').insert({
        'profile_id': profileId,
        'status': 'pendiente',
        'gross_amount': total,
        'commission_amount': double.parse(monto.toStringAsFixed(0)),
        'created_at': now.toIso8601String(),
      }).select('id').single();
      final id = row['id']?.toString() ?? 'sol-${now.millisecondsSinceEpoch}';
      
      final nombreCompleto = '${selected['nombres']} ${selected['apellidos']}';
      
      final solicitud = AdminPagoSolicitud(
        id: id,
        profileId: profileId,
        conductor: nombreCompleto.trim(),
        placa: selected['placa']?.toString() ?? '',
        monto: double.parse(monto.toStringAsFixed(0)),
        porcentaje: porcentaje,
        totalRecaudado: total,
        solicitadoAt: now,
        detalleViajes: detalleViajes,
      );
      state = state.copyWith(
        solicitudesPendientes: [...state.solicitudesPendientes, solicitud],
        banner: AdminPagoBanner(
          solicitudId: solicitud.id,
          message: 'Nueva solicitud de pago — ${nombreCompleto.trim()}: S/ ${solicitud.monto.toStringAsFixed(0)}',
        ),
      );
      return solicitud;
    } catch (_) {
      return null;
    }
  }

  void clearBanner() {
    state = state.copyWith(clearBanner: true);
  }
}

final adminPagosProvider = StateNotifierProvider<AdminPagosController, AdminPagosState>(
  (ref) => AdminPagosController(ref: ref),
);

class AdminPagoSolicitud {
  const AdminPagoSolicitud({
    required this.id,
    required this.profileId,
    required this.conductor,
    required this.placa,
    required this.monto,
    required this.porcentaje,
    required this.totalRecaudado,
    required this.solicitadoAt,
    required this.detalleViajes,
  });

  final String id;
  final String profileId;
  final String conductor;
  final String placa;
  final double monto;
  final double porcentaje;
  final double totalRecaudado;
  final DateTime solicitadoAt;
  final List<AdminPagoDetalleViaje> detalleViajes;
}

class AdminPagoHistorial {
  const AdminPagoHistorial({
    required this.id,
    required this.conductor,
    required this.placa,
    required this.monto,
    required this.porcentaje,
    required this.totalRecaudado,
    required this.confirmadoAt,
    required this.estado,
    required this.detalleViajes,
  });

  final String id;
  final String conductor;
  final String placa;
  final double monto;
  final double porcentaje;
  final double totalRecaudado;
  final DateTime confirmadoAt;
  final String estado;
  final List<AdminPagoDetalleViaje> detalleViajes;
}

class AdminPagoDetalleViaje {
  const AdminPagoDetalleViaje({
    required this.label,
    required this.monto,
  });

  final String label;
  final double monto;
}

class AdminPagoBanner {
  const AdminPagoBanner({
    required this.solicitudId,
    required this.message,
  });

  final String solicitudId;
  final String message;
}

Future<List<AdminPagoDetalleViaje>> _fetchDetalleViajes(String driverId, DateTime until) async {
  try {
    final tripsRaw = await Supabase.instance.client
        .from('trips')
        .select('id, amount, created_at, status')
        .eq('driver_id', driverId)
        .eq('status', 'completado')
        .lte('created_at', until.toIso8601String())
        .order('created_at', ascending: false)
        .limit(10);
        
    final list = <AdminPagoDetalleViaje>[];
    int count = 1;
    for (final tm in (tripsRaw as List).cast<Map<String, dynamic>>()) {
      final amount = ((tm['amount'] as num?)?.toDouble()) ?? 0.0;
      final createdAtStr = tm['created_at']?.toString() ?? '';
      final dt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
      
      String two(int v) => v.toString().padLeft(2, '0');
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '${two(h)}:${two(dt.minute)} $ampm';
      
      list.add(AdminPagoDetalleViaje(label: 'Viaje $count · $timeStr', monto: amount));
      count++;
    }
    return list;
  } catch (_) {
    return [];
  }
}
