import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_data.dart';

class AdminConductoresState {
  const AdminConductoresState({
    required this.listaConductores,
    required this.conductorSeleccionado,
    required this.queryBusqueda,
    required this.filtroEstado,
    required this.viajes,
  });

  final List<MockAdminConductor> listaConductores;
  final String? conductorSeleccionado;
  final String queryBusqueda;
  final MockAdminConductorEstado? filtroEstado;
  final List<MockAdminViaje> viajes;

  MockAdminConductor? get conductorSeleccionadoObj {
    final id = conductorSeleccionado;
    if (id == null) return null;
    for (final c in listaConductores) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<MockAdminConductor> get listaFiltrada {
    final q = queryBusqueda.trim().toLowerCase();
    final f = filtroEstado;
    final filtered = <MockAdminConductor>[];
    for (final c in listaConductores) {
      if (f != null && c.estado != f) continue;
      if (q.isEmpty) {
        filtered.add(c);
        continue;
      }
      final haystack = '${c.nombreCompleto} ${c.placa}'.toLowerCase();
      if (haystack.contains(q)) filtered.add(c);
    }
    return filtered;
  }

  static AdminConductoresState initial() => AdminConductoresState(
        listaConductores: const [],
        conductorSeleccionado: null,
        queryBusqueda: '',
        filtroEstado: null,
        viajes: const [],
      );
}

class AdminConductoresController extends StateNotifier<AdminConductoresState> {
  AdminConductoresController() : super(AdminConductoresState.initial()) {
    _loadFromSupabase();
  }

  static final _dniRe = RegExp(r'^\d{8}$');
  static final _telefonoRe = RegExp(r'^\d{9}$');
  static final _placaRe = RegExp(r'^[A-Z]{3}-\d{3}$');
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _loadFromSupabase() async {
    try {
      final driversRaw = await Supabase.instance.client
          .from('drivers')
          .select('id, profile_id, plate, vehicle_type, capacity, commission_pct, rating_avg, rating_count, estado, pago_confirmado, cuenta_activa');

      final drivers = <Map<String, dynamic>>[];
      final profileIds = <String>{};
      for (final dm in (driversRaw as List).cast<Map<String, dynamic>>()) {
        final pid = dm['profile_id']?.toString();
        if (pid == null) continue;
        profileIds.add(pid);
        drivers.add(dm);
      }

      final profilesById = <String, Map<String, dynamic>>{};
      if (profileIds.isNotEmpty) {
        final profilesRaw = await Supabase.instance.client
            .from('profiles')
            .select('id, first_name, last_name, dni, phone, email')
            .inFilter('id', profileIds.toList());
        for (final pm in (profilesRaw as List).cast<Map<String, dynamic>>()) {
          final id = pm['id']?.toString();
          if (id != null) profilesById[id] = pm;
        }
      }

      final conductores = <MockAdminConductor>[];
      for (final d in drivers) {
        final pid = d['profile_id']?.toString();
        if (pid == null) continue;
        final p = profilesById[pid];
        final nombres = p?['first_name']?.toString() ?? '';
        final apellidos = p?['last_name']?.toString() ?? '';
        final dni = p?['dni']?.toString() ?? '—';
        final telefono = p?['phone']?.toString() ?? '—';
        final correo = p?['email']?.toString() ?? '—';
        final placa = d['plate']?.toString() ?? '—';
        final vehiculoTipo = d['vehicle_type']?.toString() ?? '—';
        final capacidad = (d['capacity'] as int?) ?? 0;
        final comision = ((d['commission_pct'] as num?)?.toDouble()) ?? 15.0;
        final ratingAvg = ((d['rating_avg'] as num?)?.toDouble()) ?? 0.0;
        final ratingCount = (d['rating_count'] as int?) ?? 0;
        final cuentaActiva = (d['cuenta_activa'] as bool?) ?? true;
        final pagoConfirmado = (d['pago_confirmado'] as bool?) ?? false;
        final estadoRaw = d['estado']?.toString();

        final estado = !cuentaActiva
            ? MockAdminConductorEstado.inactivo
            : (!pagoConfirmado
                ? MockAdminConductorEstado.bloqueado
                : (estadoRaw == 'enRuta'
                    ? MockAdminConductorEstado.enRuta
                    : MockAdminConductorEstado.disponible));

        conductores.add(
          MockAdminConductor(
            id: pid,
            nombres: nombres.isEmpty ? '—' : nombres,
            apellidos: apellidos.isEmpty ? '—' : apellidos,
            dni: dni,
            telefono: telefono,
            correo: correo,
            placa: placa,
            vehiculoTipo: vehiculoTipo,
            capacidad: capacidad,
            comisionPorcentaje: comision,
            ratingPromedio: ratingAvg,
            ratingCount: ratingCount,
            estado: estado,
            bloqueadoPorPago: !pagoConfirmado,
          ),
        );
      }

      final tripsRaw = await Supabase.instance.client
          .from('trips')
          .select('id, driver_id, created_at, amount, status, route_id')
          .order('created_at', ascending: false)
          .limit(200);
      final viajes = <MockAdminViaje>[];
      for (final tm in (tripsRaw as List).cast<Map<String, dynamic>>()) {
          final id = tm['id']?.toString();
          final driverId = tm['driver_id']?.toString();
          final createdAt = DateTime.tryParse(tm['created_at']?.toString() ?? '');
          final monto = ((tm['amount'] as num?)?.toDouble()) ?? 0.0;
          final status = tm['status']?.toString();
          final routeId = tm['route_id']?.toString();
          if (id == null || driverId == null || createdAt == null || status == null) continue;

          String rutaLabel = 'Ruta';
          if (routeId != null) {
            final route = await Supabase.instance.client.from('routes').select('name').eq('id', routeId).maybeSingle();
            rutaLabel = route?['name']?.toString() ?? rutaLabel;
          }

          final conductorProfileId = drivers
              .firstWhere(
                (d) => d['id']?.toString() == driverId,
                orElse: () => const <String, dynamic>{},
              )['profile_id']
              ?.toString();

          viajes.add(
            MockAdminViaje(
              id: id,
              conductorId: conductorProfileId ?? driverId,
              fecha: createdAt,
              rutaLabel: rutaLabel,
              monto: monto,
              estado: status == 'cancelado' ? MockAdminViajeEstado.cancelado : MockAdminViajeEstado.completado,
            ),
          );
      }

      state = _copyWith(
        listaConductores: conductores,
        viajes: viajes,
      );
    } catch (_) {}
  }

  void buscarConductor(String query) {
    state = _copyWith(queryBusqueda: query);
  }

  void seleccionarConductor(String? id) {
    state = _copyWith(conductorSeleccionado: id);
  }

  void setFiltroEstado(MockAdminConductorEstado? estado) {
    state = _copyWith(filtroEstado: estado);
  }

  AdminCrearConductorResult crearConductor({
    required String nombres,
    required String apellidos,
    required String dni,
    String? telefono,
    required String correo,
    required String placa,
    required String vehiculoTipo,
    required int capacidad,
    required double comisionPorcentaje,
  }) {
    final n = nombres.trim();
    final a = apellidos.trim();
    final d = dni.trim();
    final t = (telefono ?? '').trim();
    final c = correo.trim().toLowerCase();
    final p = placa.trim().toUpperCase();
    final v = vehiculoTipo.trim();

    if (n.isEmpty || a.isEmpty) {
      return const AdminCrearConductorResult.invalid('Completa nombres y apellidos');
    }
    if (!_dniRe.hasMatch(d)) {
      return const AdminCrearConductorResult.invalid('DNI inválido');
    }
    if (t.isNotEmpty && !_telefonoRe.hasMatch(t)) {
      return const AdminCrearConductorResult.invalid('Teléfono inválido');
    }
    if (!_emailRe.hasMatch(c)) {
      return const AdminCrearConductorResult.invalid('Correo inválido');
    }
    if (!_placaRe.hasMatch(p)) {
      return const AdminCrearConductorResult.invalid('Placa inválida');
    }
    if (capacidad <= 0) {
      return const AdminCrearConductorResult.invalid('Capacidad inválida');
    }
    if (comisionPorcentaje <= 0 || comisionPorcentaje > 100) {
      return const AdminCrearConductorResult.invalid('Comisión inválida');
    }

    for (final item in state.listaConductores) {
      if (item.dni == d) {
        return const AdminCrearConductorResult.duplicateDni();
      }
      if (item.placa.toUpperCase() == p) {
        return const AdminCrearConductorResult.duplicatePlaca();
      }
    }

    final created = MockAdminConductor(
      id: d,
      nombres: n,
      apellidos: a,
      dni: d,
      telefono: t.isEmpty ? '—' : t,
      correo: c,
      placa: p,
      vehiculoTipo: v,
      capacidad: capacidad,
      comisionPorcentaje: comisionPorcentaje,
      ratingPromedio: 0.0,
      ratingCount: 0,
      estado: MockAdminConductorEstado.disponible,
      bloqueadoPorPago: false,
    );

    state = _copyWith(
      listaConductores: [created, ...state.listaConductores],
      conductorSeleccionado: created.id,
    );
    return AdminCrearConductorResult.ok(createdId: created.id);
  }

  AdminEditarConductorResult editarConductor({
    required String id,
    required String nombres,
    required String apellidos,
    required String dni,
    String? telefono,
    required String correo,
    required String placa,
    required String vehiculoTipo,
    required int capacidad,
    required double comisionPorcentaje,
  }) {
    final current = getById(id);
    if (current == null) return const AdminEditarConductorResult.notFound();

    final n = nombres.trim();
    final a = apellidos.trim();
    final d = dni.trim();
    final t = (telefono ?? '').trim();
    final c = correo.trim().toLowerCase();
    final p = placa.trim().toUpperCase();
    final v = vehiculoTipo.trim();

    if (n.isEmpty || a.isEmpty) {
      return const AdminEditarConductorResult.invalid('Completa nombres y apellidos');
    }
    if (!_dniRe.hasMatch(d)) {
      return const AdminEditarConductorResult.invalid('DNI inválido');
    }
    if (t.isNotEmpty && !_telefonoRe.hasMatch(t)) {
      return const AdminEditarConductorResult.invalid('Teléfono inválido');
    }
    if (!_emailRe.hasMatch(c)) {
      return const AdminEditarConductorResult.invalid('Correo inválido');
    }
    if (!_placaRe.hasMatch(p)) {
      return const AdminEditarConductorResult.invalid('Placa inválida');
    }
    if (capacidad <= 0) {
      return const AdminEditarConductorResult.invalid('Capacidad inválida');
    }
    if (comisionPorcentaje <= 0 || comisionPorcentaje > 100) {
      return const AdminEditarConductorResult.invalid('Comisión inválida');
    }

    for (final item in state.listaConductores) {
      if (item.id == id) continue;
      if (item.dni == d) return const AdminEditarConductorResult.duplicateDni();
      if (item.placa.toUpperCase() == p) return const AdminEditarConductorResult.duplicatePlaca();
    }

    final next = current.copyWith(
      nombres: n,
      apellidos: a,
      dni: d,
      telefono: t.isEmpty ? '—' : t,
      correo: c,
      placa: p,
      vehiculoTipo: v,
      capacidad: capacidad,
      comisionPorcentaje: comisionPorcentaje,
    );

    state = _copyWith(
      listaConductores: [
        for (final item in state.listaConductores) if (item.id == id) next else item,
      ],
    );
    return const AdminEditarConductorResult.ok();
  }

  void desactivarConductor(String id) {
    final current = getById(id);
    if (current == null) return;
    if (current.estado == MockAdminConductorEstado.inactivo) return;
    final next = current.copyWith(estado: MockAdminConductorEstado.inactivo);
    state = _copyWith(
      listaConductores: [
        for (final item in state.listaConductores) if (item.id == id) next else item,
      ],
    );
  }

  void reactivarConductor(String id) {
    final current = getById(id);
    if (current == null) return;
    if (current.estado != MockAdminConductorEstado.inactivo) return;
    final next = current.copyWith(estado: MockAdminConductorEstado.disponible);
    state = _copyWith(
      listaConductores: [
        for (final item in state.listaConductores) if (item.id == id) next else item,
      ],
    );
  }

  void desbloquearConductor(String id) {
    final current = getById(id);
    if (current == null) return;
    if (current.estado != MockAdminConductorEstado.bloqueado && !current.bloqueadoPorPago) return;
    final next = current.copyWith(
      estado: MockAdminConductorEstado.disponible,
      bloqueadoPorPago: false,
    );
    state = _copyWith(
      listaConductores: [
        for (final item in state.listaConductores) if (item.id == id) next else item,
      ],
    );
  }

  void actualizarComision(String id, double nuevoPorcentaje) {
    final current = getById(id);
    if (current == null) return;
    if (nuevoPorcentaje <= 0 || nuevoPorcentaje > 100) return;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final effective = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final next = current.copyWith(
      comisionPendientePorcentaje: nuevoPorcentaje,
      comisionPendienteDesde: effective,
    );
    state = _copyWith(
      listaConductores: [
        for (final item in state.listaConductores) if (item.id == id) next else item,
      ],
    );
  }

  MockAdminConductor? getById(String id) {
    for (final c in state.listaConductores) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<MockAdminViaje> viajesDeConductor(String conductorId) {
    final list = <MockAdminViaje>[];
    for (final v in state.viajes) {
      if (v.conductorId == conductorId) list.add(v);
    }
    list.sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  MockAdminViaje? getViajeById(String viajeId) {
    for (final v in state.viajes) {
      if (v.id == viajeId) return v;
    }
    return null;
  }

  AdminConductoresState _copyWith({
    List<MockAdminConductor>? listaConductores,
    String? conductorSeleccionado,
    String? queryBusqueda,
    MockAdminConductorEstado? filtroEstado,
    List<MockAdminViaje>? viajes,
  }) {
    return AdminConductoresState(
      listaConductores: listaConductores ?? state.listaConductores,
      conductorSeleccionado: conductorSeleccionado ?? state.conductorSeleccionado,
      queryBusqueda: queryBusqueda ?? state.queryBusqueda,
      filtroEstado: filtroEstado ?? state.filtroEstado,
      viajes: viajes ?? state.viajes,
    );
  }
}

final adminConductoresProvider =
    StateNotifierProvider<AdminConductoresController, AdminConductoresState>(
  (ref) => AdminConductoresController(),
);

class AdminCrearConductorResult {
  const AdminCrearConductorResult._(this.type, {this.message, this.createdId});

  final AdminCrearConductorResultType type;
  final String? message;
  final String? createdId;

  const AdminCrearConductorResult.ok({required String createdId})
      : this._(AdminCrearConductorResultType.ok, createdId: createdId);

  const AdminCrearConductorResult.invalid(String message)
      : this._(AdminCrearConductorResultType.invalid, message: message);

  const AdminCrearConductorResult.duplicateDni()
      : this._(AdminCrearConductorResultType.duplicateDni);

  const AdminCrearConductorResult.duplicatePlaca()
      : this._(AdminCrearConductorResultType.duplicatePlaca);
}

enum AdminCrearConductorResultType { ok, invalid, duplicateDni, duplicatePlaca }

class AdminEditarConductorResult {
  const AdminEditarConductorResult._(this.type, {this.message});

  final AdminEditarConductorResultType type;
  final String? message;

  const AdminEditarConductorResult.ok() : this._(AdminEditarConductorResultType.ok);

  const AdminEditarConductorResult.notFound() : this._(AdminEditarConductorResultType.notFound);

  const AdminEditarConductorResult.invalid(String message)
      : this._(AdminEditarConductorResultType.invalid, message: message);

  const AdminEditarConductorResult.duplicateDni()
      : this._(AdminEditarConductorResultType.duplicateDni);

  const AdminEditarConductorResult.duplicatePlaca()
      : this._(AdminEditarConductorResultType.duplicatePlaca);
}

enum AdminEditarConductorResultType { ok, notFound, invalid, duplicateDni, duplicatePlaca }
