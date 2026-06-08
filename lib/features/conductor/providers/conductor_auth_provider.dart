import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conductor_viaje_provider.dart';

enum ConductorEstadoActual {
  disponible,
  activo,
  enRuta,
  finalizado,
}

class ConductorAuthState {
  const ConductorAuthState({
    required this.conductorLogueado,
    required this.pagoConfirmado,
    required this.lastPagoConfirmadoAt,
    required this.accesoOperativo,
    required this.estadoActual,
  });

  final bool conductorLogueado;
  final bool pagoConfirmado;
  final DateTime? lastPagoConfirmadoAt;
  final bool accesoOperativo;
  final ConductorEstadoActual estadoActual;

  ConductorAuthState copyWith({
    bool? conductorLogueado,
    bool? pagoConfirmado,
    DateTime? lastPagoConfirmadoAt,
    bool clearLastPagoConfirmadoAt = false,
    bool? accesoOperativo,
    ConductorEstadoActual? estadoActual,
  }) {
    return ConductorAuthState(
      conductorLogueado: conductorLogueado ?? this.conductorLogueado,
      pagoConfirmado: pagoConfirmado ?? this.pagoConfirmado,
      lastPagoConfirmadoAt:
          clearLastPagoConfirmadoAt ? null : (lastPagoConfirmadoAt ?? this.lastPagoConfirmadoAt),
      accesoOperativo: accesoOperativo ?? this.accesoOperativo,
      estadoActual: estadoActual ?? this.estadoActual,
    );
  }

  static const initial = ConductorAuthState(
    conductorLogueado: false,
    pagoConfirmado: false,
    lastPagoConfirmadoAt: null,
    accesoOperativo: false,
    estadoActual: ConductorEstadoActual.disponible,
  );
}

enum ConductorLoginResult {
  ok,
  invalidCredentials,
  inactiveAccount,
}

class ConductorAuthController extends StateNotifier<ConductorAuthState> {
  ConductorAuthController() : super(ConductorAuthState.initial) {
    _load();
  }

  static const _systemStartMinKey = 'sdag_system_operating_start_min';
  static const _systemEndMinKey = 'sdag_system_operating_end_min';
  static const _systemRunMonFriKey = 'sdag_system_operating_monfri';
  static const _systemRunSatKey = 'sdag_system_operating_sat';
  static const _systemRunSunKey = 'sdag_system_operating_sun';

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = ConductorAuthState.initial;
      return;
    }

    final role = await _roleForUser(user.id);
    if (!mounted) return;
    if (role != 'driver') {
      state = ConductorAuthState.initial;
      return;
    }

    final driver = await _getDriverByProfileId(user.id);
    if (!mounted) return;
    if (driver == null) {
      state = state.copyWith(
        conductorLogueado: true,
        pagoConfirmado: false,
        lastPagoConfirmadoAt: null,
        accesoOperativo: false,
        estadoActual: ConductorEstadoActual.disponible,
      );
      return;
    }

    final cuentaActiva = (driver['cuenta_activa'] as bool?) ?? true;
    final pago = (driver['pago_confirmado'] as bool?) ?? false;
    final estado = _estadoFromString(driver['estado']?.toString()) ?? ConductorEstadoActual.disponible;
    final pagoAt = DateTime.tryParse(driver['last_pago_confirmado_at']?.toString() ?? '');

    state = state.copyWith(
      conductorLogueado: cuentaActiva,
      pagoConfirmado: pago,
      lastPagoConfirmadoAt: pagoAt,
      accesoOperativo: cuentaActiva && pago,
      estadoActual: estado,
    );
  }

  ConductorEstadoActual? _estadoFromString(String? value) {
    if (value == null) return null;
    for (final e in ConductorEstadoActual.values) {
      if (e.name == value) return e;
    }
    return null;
  }

  Future<ConductorLoginResult> login({
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    final p = password.trim();
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(email: e, password: p);
      final user = res.user ?? Supabase.instance.client.auth.currentUser;
      if (user == null) return ConductorLoginResult.invalidCredentials;

      final role = await _roleForUser(user.id);
      if (role != 'driver') {
        return ConductorLoginResult.invalidCredentials;
      }

      final driver = await _getDriverByProfileId(user.id);
      final cuentaActiva = (driver?['cuenta_activa'] as bool?) ?? true;
      if (!cuentaActiva) return ConductorLoginResult.inactiveAccount;

      final pago = (driver?['pago_confirmado'] as bool?) ?? false;
      final estado = _estadoFromString(driver?['estado']?.toString()) ?? ConductorEstadoActual.disponible;
      final pagoAt = DateTime.tryParse(driver?['last_pago_confirmado_at']?.toString() ?? '');

      if (!mounted) return ConductorLoginResult.ok;
      state = state.copyWith(
        conductorLogueado: true,
        pagoConfirmado: pago,
        lastPagoConfirmadoAt: pagoAt,
        accesoOperativo: pago,
        estadoActual: estado,
      );
      return ConductorLoginResult.ok;
    } on AuthException {
      return ConductorLoginResult.invalidCredentials;
    }
  }

  Future<void> logout() async {
    state = ConductorAuthState.initial;
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> confirmarPago() async {
    final now = DateTime.now();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('drivers').update({
      'pago_confirmado': true,
      'last_pago_confirmado_at': now.toIso8601String(),
    }).eq('profile_id', user.id);
    if (!mounted) return;
    state = state.copyWith(
      pagoConfirmado: true,
      lastPagoConfirmadoAt: now,
      accesoOperativo: state.conductorLogueado,
    );
  }

  Future<ConductorDisponibilidadResult> activarDisponibilidad() async {
    if (!state.accesoOperativo) return ConductorDisponibilidadResult.accesoBloqueado;
    final prefs = await SharedPreferences.getInstance();
    final okHorario = _isWithinOperationalHours(DateTime.now(), prefs);
    if (!okHorario) return ConductorDisponibilidadResult.fueraDeHorario;
    await _updateDriverEstado(ConductorEstadoActual.disponible);
    if (!mounted) return ConductorDisponibilidadResult.ok;
    state = state.copyWith(estadoActual: ConductorEstadoActual.disponible);
    return ConductorDisponibilidadResult.ok;
  }

  Future<void> desactivarDisponibilidad() async {
    if (!state.accesoOperativo) return;
    await _updateDriverEstado(ConductorEstadoActual.finalizado);
    if (!mounted) return;
    state = state.copyWith(estadoActual: ConductorEstadoActual.finalizado);
  }

  Future<void> syncWithViaje(ConductorViajeState viaje) async {
    if (!state.conductorLogueado) return;
    if (!state.accesoOperativo) return;

    ConductorEstadoActual? target;
    if (viaje.estadoViaje == ConductorEstadoViaje.enRuta) {
      target = ConductorEstadoActual.enRuta;
    } else if (viaje.isActive && viaje.occupiedSeats > 0) {
      target = ConductorEstadoActual.activo;
    } else if (viaje.estadoViaje == ConductorEstadoViaje.completado) {
      final prefs = await SharedPreferences.getInstance();
      final okHorario = _isWithinOperationalHours(DateTime.now(), prefs);
      target = okHorario ? ConductorEstadoActual.disponible : ConductorEstadoActual.finalizado;
    }

    if (target == null) return;
    if (state.estadoActual == target) return;

    await _updateDriverEstado(target);
    if (!mounted) return;
    state = state.copyWith(estadoActual: target);
  }

  bool _isWithinOperationalHours(DateTime now, SharedPreferences prefs) {
    final weekday = now.weekday;
    final runMonFri = prefs.getBool(_systemRunMonFriKey) ?? true;
    final runSat = prefs.getBool(_systemRunSatKey) ?? true;
    final runSun = prefs.getBool(_systemRunSunKey) ?? true;
    final allowedDay = switch (weekday) {
      DateTime.saturday => runSat,
      DateTime.sunday => runSun,
      _ => runMonFri,
    };
    if (!allowedDay) return false;

    final start = prefs.getInt(_systemStartMinKey) ?? (5 * 60);
    final end = prefs.getInt(_systemEndMinKey) ?? (22 * 60);
    if (start == end) return false;

    final min = now.hour * 60 + now.minute;
    if (start < end) {
      return min >= start && min <= end;
    }
    return min >= start || min <= end;
  }

  Future<String?> _roleForUser(String userId) async {
    final row = await Supabase.instance.client.from('profiles').select('role').eq('id', userId).maybeSingle();
    return row?['role']?.toString();
  }

  Future<Map<String, dynamic>?> _getDriverByProfileId(String profileId) async {
    final row = await Supabase.instance.client.from('drivers').select().eq('profile_id', profileId).maybeSingle();
    return row;
  }

  Future<void> _updateDriverEstado(ConductorEstadoActual estado) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('drivers').update({'estado': estado.name}).eq('profile_id', user.id);
  }
}

enum ConductorDisponibilidadResult { ok, accesoBloqueado, fueraDeHorario }

final conductorAuthProvider = StateNotifierProvider<ConductorAuthController, ConductorAuthState>(
  (ref) {
    final controller = ConductorAuthController();
    ref.listen<ConductorViajeState>(conductorViajeProvider, (prev, next) {
      controller.syncWithViaje(next);
    });
    return controller;
  },
);
