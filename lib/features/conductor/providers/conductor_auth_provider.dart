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
    required this.accesoOperativo,
    required this.estadoActual,
  });

  final bool conductorLogueado;
  final bool accesoOperativo;
  final ConductorEstadoActual estadoActual;

  ConductorAuthState copyWith({
    bool? conductorLogueado,
    bool? accesoOperativo,
    ConductorEstadoActual? estadoActual,
  }) {
    return ConductorAuthState(
      conductorLogueado: conductorLogueado ?? this.conductorLogueado,
      accesoOperativo: accesoOperativo ?? this.accesoOperativo,
      estadoActual: estadoActual ?? this.estadoActual,
    );
  }

  static const initial = ConductorAuthState(
    conductorLogueado: false,
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
        accesoOperativo: false,
        estadoActual: ConductorEstadoActual.disponible,
      );
      return;
    }

    final cuentaActiva = (driver['cuenta_activa'] as bool?) ?? true;

    final estado = _estadoFromString(driver['estado']?.toString()) ?? ConductorEstadoActual.disponible;

    state = state.copyWith(
      conductorLogueado: cuentaActiva,
      accesoOperativo: cuentaActiva,
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

      final estado = _estadoFromString(driver?['estado']?.toString()) ?? ConductorEstadoActual.disponible;

      if (!mounted) return ConductorLoginResult.ok;
      state = state.copyWith(
        conductorLogueado: true,
         accesoOperativo: cuentaActiva,
        estadoActual: estado,
      );
      return ConductorLoginResult.ok;
    } on AuthException {
      return ConductorLoginResult.invalidCredentials;
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = ConductorAuthState.initial;
  }

  Future<ConductorDisponibilidadResult> activarDisponibilidad() async {
    // Verificar primero si el chofer tiene permiso operativo
    if (!state.accesoOperativo) {
      return ConductorDisponibilidadResult.accesoBloqueado;
    }

    final prefs = await SharedPreferences.getInstance();
    final okHorario = _isWithinOperationalHours(DateTime.now(), prefs);
    if (!okHorario) return ConductorDisponibilidadResult.fueraDeHorario;
    await _updateDriverEstado(ConductorEstadoActual.disponible);
    if (!mounted) return ConductorDisponibilidadResult.ok;
    state = state.copyWith(estadoActual: ConductorEstadoActual.disponible);
    return ConductorDisponibilidadResult.ok;
  }

  Future<void> desactivarDisponibilidad() async {
    await _updateDriverEstado(ConductorEstadoActual.finalizado);
    if (!mounted) return;
    state = state.copyWith(estadoActual: ConductorEstadoActual.finalizado);
  }

  Future<void> syncWithViaje(ConductorViajeState viaje) async {
    if (!state.conductorLogueado) return;

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
