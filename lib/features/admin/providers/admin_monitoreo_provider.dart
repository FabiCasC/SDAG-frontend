import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    cargarFlota();
    _startMovement();
    ref.onDispose(() {
      _timer?.cancel();
    });
  }

  final Ref ref;
  Timer? _timer;

  void cargarFlota() {
    final conductores = ref.read(adminConductoresProvider).listaConductores;
    final items = <AdminVehiculoActivo>[];

    for (var i = 0; i < conductores.length; i++) {
      final c = conductores[i];
      final estado = switch (c.estado) {
        MockAdminConductorEstado.enRuta => AdminVehiculoEstado.enRuta,
        MockAdminConductorEstado.disponible => AdminVehiculoEstado.disponible,
        MockAdminConductorEstado.inactivo => AdminVehiculoEstado.inactivo,
        MockAdminConductorEstado.bloqueado => AdminVehiculoEstado.inactivo,
      };

      final routePoints = _routePointsForEstado(estado);
      final pos = routePoints.isEmpty ? const LatLng(-12.0464, -76.9156) : routePoints[i % routePoints.length];
      final capacity = c.capacidad;
      final ocupados = _occupancyForIndex(i, capacity);
      final eta = estado == AdminVehiculoEstado.enRuta ? 18 + (i * 3) % 15 : null;

      items.add(
        AdminVehiculoActivo(
          conductorId: c.id,
          conductorNombre: c.nombreCompleto,
          placa: c.placa,
          estado: estado == AdminVehiculoEstado.disponible && i % 5 == 2 ? AdminVehiculoEstado.activo : estado,
          posicion: pos,
          rutaLabel: estado == AdminVehiculoEstado.enRuta ? _routeLabelForConductor(c) : null,
          ocupados: ocupados,
          capacidad: capacity,
          etaMinutos: eta,
          routeIndex: i % (routePoints.isEmpty ? 1 : routePoints.length),
          routePoints: routePoints,
        ),
      );
    }

    state = state.copyWith(vehiculosActivos: items);
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
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final next = <AdminVehiculoActivo>[];
      for (final v in state.vehiculosActivos) {
        if (v.routePoints.isEmpty || v.estado == AdminVehiculoEstado.inactivo) {
          next.add(v);
          continue;
        }
        final idx = (v.routeIndex + 1) % v.routePoints.length;
        final pos = v.routePoints[idx];
        final eta = v.estado == AdminVehiculoEstado.enRuta
            ? (6 + ((v.routePoints.length - idx) * 4)).clamp(3, 60)
            : v.etaMinutos;
        next.add(v.copyWith(routeIndex: idx, posicion: pos, etaMinutos: eta));
      }
      state = state.copyWith(vehiculosActivos: next);
    });
  }

  static List<LatLng> _routePointsForEstado(AdminVehiculoEstado estado) {
    const sanIsidro = LatLng(-12.0931, -76.9662);
    const mid1 = LatLng(-12.0670, -76.9450);
    const mid2 = LatLng(-12.0464, -76.9156);
    const mid3 = LatLng(-12.0000, -76.8600);
    const chosica = LatLng(-11.9333, -76.7000);

    switch (estado) {
      case AdminVehiculoEstado.enRuta:
        return const [sanIsidro, mid2, mid3, chosica];
      case AdminVehiculoEstado.activo:
        return const [mid1, mid2, mid1, mid2];
      case AdminVehiculoEstado.disponible:
        return const [sanIsidro, mid1, sanIsidro];
      case AdminVehiculoEstado.inactivo:
        return const [mid2];
    }
  }

  static int _occupancyForIndex(int i, int capacity) {
    if (capacity <= 0) return 0;
    final value = 1 + ((i * 3) % capacity);
    return value.clamp(0, capacity);
  }

  static String _routeLabelForConductor(MockAdminConductor c) {
    final dir = c.placa.hashCode.isEven ? 'San Isidro → Chosica' : 'Chosica → San Isidro';
    final via = c.placa.hashCode % 3 == 0 ? 'Vía Javier Prado' : 'Vía La Priale';
    return '$dir · $via';
  }
}

final adminMonitoreoProvider =
    StateNotifierProvider<AdminMonitoreoController, AdminMonitoreoState>(
  (ref) => AdminMonitoreoController(ref: ref),
);
