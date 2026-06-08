import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_data.dart';
import 'admin_conductores_provider.dart';

enum AdminVehiculoEstado {
  disponible,
  enRuta,
  activo,
  inactivo,
}

enum AdminManifiestoEstadoFiltro {
  todos,
  completado,
  enCurso,
}

enum AdminViajeRutaFiltro {
  todos,
  sanIsidroChosica,
  chosicaSanIsidro,
}

class AdminVehiculoActivo {
  const AdminVehiculoActivo({
    required this.conductorId,
    required this.conductorNombre,
    required this.placa,
    required this.estado,
    required this.posicion,
    required this.rutaLabel,
    required this.ocupados,
    required this.capacidad,
    required this.etaMinutos,
    required this.routeIndex,
    required this.routePoints,
  });

  final String conductorId;
  final String conductorNombre;
  final String placa;
  final AdminVehiculoEstado estado;
  final LatLng posicion;
  final String? rutaLabel;
  final int ocupados;
  final int capacidad;
  final int? etaMinutos;
  final int routeIndex;
  final List<LatLng> routePoints;

  AdminVehiculoActivo copyWith({
    AdminVehiculoEstado? estado,
    LatLng? posicion,
    String? rutaLabel,
    int? ocupados,
    int? capacidad,
    int? etaMinutos,
    int? routeIndex,
    List<LatLng>? routePoints,
  }) {
    return AdminVehiculoActivo(
      conductorId: conductorId,
      conductorNombre: conductorNombre,
      placa: placa,
      estado: estado ?? this.estado,
      posicion: posicion ?? this.posicion,
      rutaLabel: rutaLabel ?? this.rutaLabel,
      ocupados: ocupados ?? this.ocupados,
      capacidad: capacidad ?? this.capacidad,
      etaMinutos: etaMinutos ?? this.etaMinutos,
      routeIndex: routeIndex ?? this.routeIndex,
      routePoints: routePoints ?? this.routePoints,
    );
  }
}

class AdminMonitoreoState {
  const AdminMonitoreoState({
    required this.vehiculosActivos,
    required this.manifiestoQuery,
    required this.manifiestoDesde,
    required this.manifiestoHasta,
    required this.manifiestoEstado,
    required this.viajesQuery,
    required this.viajesDesde,
    required this.viajesHasta,
    required this.viajesRuta,
    required this.viajeSeleccionado,
  });

  final List<AdminVehiculoActivo> vehiculosActivos;

  final String manifiestoQuery;
  final DateTime? manifiestoDesde;
  final DateTime? manifiestoHasta;
  final AdminManifiestoEstadoFiltro manifiestoEstado;

  final String viajesQuery;
  final DateTime? viajesDesde;
  final DateTime? viajesHasta;
  final AdminViajeRutaFiltro viajesRuta;

  final String? viajeSeleccionado;

  AdminMonitoreoState copyWith({
    List<AdminVehiculoActivo>? vehiculosActivos,
    String? manifiestoQuery,
    DateTime? manifiestoDesde,
    DateTime? manifiestoHasta,
    AdminManifiestoEstadoFiltro? manifiestoEstado,
    String? viajesQuery,
    DateTime? viajesDesde,
    DateTime? viajesHasta,
    AdminViajeRutaFiltro? viajesRuta,
    String? viajeSeleccionado,
  }) {
    return AdminMonitoreoState(
      vehiculosActivos: vehiculosActivos ?? this.vehiculosActivos,
      manifiestoQuery: manifiestoQuery ?? this.manifiestoQuery,
      manifiestoDesde: manifiestoDesde ?? this.manifiestoDesde,
      manifiestoHasta: manifiestoHasta ?? this.manifiestoHasta,
      manifiestoEstado: manifiestoEstado ?? this.manifiestoEstado,
      viajesQuery: viajesQuery ?? this.viajesQuery,
      viajesDesde: viajesDesde ?? this.viajesDesde,
      viajesHasta: viajesHasta ?? this.viajesHasta,
      viajesRuta: viajesRuta ?? this.viajesRuta,
      viajeSeleccionado: viajeSeleccionado ?? this.viajeSeleccionado,
    );
  }

  static AdminMonitoreoState initial() => const AdminMonitoreoState(
        vehiculosActivos: [],
        manifiestoQuery: '',
        manifiestoDesde: null,
        manifiestoHasta: null,
        manifiestoEstado: AdminManifiestoEstadoFiltro.todos,
        viajesQuery: '',
        viajesDesde: null,
        viajesHasta: null,
        viajesRuta: AdminViajeRutaFiltro.todos,
        viajeSeleccionado: null,
      );
}

class AdminMonitoreoController extends StateNotifier<AdminMonitoreoState> {
  AdminMonitoreoController({required this.ref}) : super(AdminMonitoreoState.initial()) {
    _loadLocations();
    _startMovement();
    ref.onDispose(() {
      _timer?.cancel();
    });
  }

  final Ref ref;
  Timer? _timer;

  void cargarFlota() {
    // Ya no se usa para datos estáticos, ahora todo se carga desde Supabase.
  }

  Future<void> _loadLocations() async {
    try {
      final data = await Supabase.instance.client
          .from('driver_locations')
          .select('*, drivers(id, profile_id, plate, profiles(first_name, last_name))')
          .neq('estado', 'inactivo');

      final next = <AdminVehiculoActivo>[];
      for (final row in (data as List).cast<Map<String, dynamic>>()) {
          final lat = (row['lat'] as num?)?.toDouble();
          final lng = (row['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          final d = row['drivers'] as Map<String, dynamic>?;
          if (d == null) continue;

          final p = d['profiles'] as Map<String, dynamic>?;
          if (p == null) continue;

          final estadoStr = row['estado']?.toString();
          AdminVehiculoEstado estado = AdminVehiculoEstado.disponible;
          if (estadoStr == 'en_ruta') {
            estado = AdminVehiculoEstado.enRuta;
          } else if (estadoStr == 'lleno') {
            estado = AdminVehiculoEstado.activo;
          } else if (estadoStr == 'esperando') {
            estado = AdminVehiculoEstado.disponible;
          }

          next.add(AdminVehiculoActivo(
            conductorId: d['profile_id'].toString(), // Usamos profile_id para mantener consistencia con los demás providers
            conductorNombre: '${p['first_name']} ${p['last_name']}',
            placa: d['plate']?.toString() ?? '—',
            estado: estado,
            posicion: LatLng(lat, lng),
            rutaLabel: estado == AdminVehiculoEstado.enRuta ? 'En Ruta' : null,
            ocupados: row['occupied_seats'] as int? ?? 0,
            capacidad: row['capacity'] as int? ?? 0,
            etaMinutos: row['eta_minutes'] as int?,
            routeIndex: 0,
            routePoints: const [],
          ));
      }
      state = state.copyWith(vehiculosActivos: next);
    } catch (_) {}
  }

  void filtrarManifiestos({
    String? query,
    DateTime? desde,
    DateTime? hasta,
    AdminManifiestoEstadoFiltro? estadoFiltro,
  }) {
    state = state.copyWith(
      manifiestoQuery: query ?? state.manifiestoQuery,
      manifiestoDesde: desde ?? state.manifiestoDesde,
      manifiestoHasta: hasta ?? state.manifiestoHasta,
      manifiestoEstado: estadoFiltro ?? state.manifiestoEstado,
    );
  }

  void filtrarViajes({
    String? query,
    DateTime? desde,
    DateTime? hasta,
    AdminViajeRutaFiltro? ruta,
  }) {
    state = state.copyWith(
      viajesQuery: query ?? state.viajesQuery,
      viajesDesde: desde ?? state.viajesDesde,
      viajesHasta: hasta ?? state.viajesHasta,
      viajesRuta: ruta ?? state.viajesRuta,
    );
  }

  void seleccionarViaje(String? viajeId) {
    state = state.copyWith(viajeSeleccionado: viajeId);
  }

  void centrarEnVehiculo(String conductorId, LatLng position) {
    final updated = [
      for (final v in state.vehiculosActivos)
        if (v.conductorId == conductorId) v.copyWith(posicion: position) else v,
    ];
    state = state.copyWith(vehiculosActivos: updated);
  }

  void _startMovement() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadLocations();
    });
  }
}

final adminMonitoreoProvider =
    StateNotifierProvider<AdminMonitoreoController, AdminMonitoreoState>(
  (ref) => AdminMonitoreoController(ref: ref),
);
