import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAuthState {
  const AdminAuthState({
    required this.adminLogueado,
    required this.intentosFallidos,
    required this.bloqueadoHastaEpochMs,
  });

  final bool adminLogueado;
  final int intentosFallidos;
  final int bloqueadoHastaEpochMs;

  bool get estaBloqueado =>
      bloqueadoHastaEpochMs > 0 && DateTime.now().millisecondsSinceEpoch < bloqueadoHastaEpochMs;

  Duration get tiempoBloqueado {
    if (!estaBloqueado) return Duration.zero;
    final diffMs = bloqueadoHastaEpochMs - DateTime.now().millisecondsSinceEpoch;
    if (diffMs <= 0) return Duration.zero;
    return Duration(milliseconds: diffMs);
  }

  AdminAuthState copyWith({
    bool? adminLogueado,
    int? intentosFallidos,
    int? bloqueadoHastaEpochMs,
  }) =>
      AdminAuthState(
        adminLogueado: adminLogueado ?? this.adminLogueado,
        intentosFallidos: intentosFallidos ?? this.intentosFallidos,
        bloqueadoHastaEpochMs: bloqueadoHastaEpochMs ?? this.bloqueadoHastaEpochMs,
      );

  static const initial = AdminAuthState(
    adminLogueado: false,
    intentosFallidos: 0,
    bloqueadoHastaEpochMs: 0,
  );
}

enum AdminLoginResult {
  ok,
  invalidCredentials,
  blocked,
}

class AdminAuthController extends StateNotifier<AdminAuthState> {
  AdminAuthController() : super(AdminAuthState.initial) {
    _load();
  }

  static const _loggedKey = 'sdag_admin_logged_in';
  static const _failedKey = 'sdag_admin_failed_attempts';
  static const _blockedUntilKey = 'sdag_admin_blocked_until_ms';
  static const _maxFailedAttempts = 5;
  static const _blockDuration = Duration(minutes: 10);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = state.copyWith(
      adminLogueado: prefs.getBool(_loggedKey) ?? false,
      intentosFallidos: prefs.getInt(_failedKey) ?? 0,
      bloqueadoHastaEpochMs: prefs.getInt(_blockedUntilKey) ?? 0,
    );
    if (loaded.bloqueadoHastaEpochMs > 0 &&
        DateTime.now().millisecondsSinceEpoch >= loaded.bloqueadoHastaEpochMs) {
      state = loaded.copyWith(
        intentosFallidos: 0,
        bloqueadoHastaEpochMs: 0,
      );
      await _persist(state);
      return;
    }
    state = loaded;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final role = await _roleForUser(user.id);
    if (role != 'admin') return;
    if (!mounted) return;
    final next = state.copyWith(
      adminLogueado: true,
      intentosFallidos: 0,
      bloqueadoHastaEpochMs: 0,
    );
    state = next;
    await _persist(next);
  }

  Future<void> _persist(AdminAuthState next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedKey, next.adminLogueado);
    await prefs.setInt(_failedKey, next.intentosFallidos);
    await prefs.setInt(_blockedUntilKey, next.bloqueadoHastaEpochMs);
  }

  Future<AdminLoginResult> login({
    required String email,
    required String password,
  }) async {
    if (state.bloqueadoHastaEpochMs > 0 &&
        DateTime.now().millisecondsSinceEpoch >= state.bloqueadoHastaEpochMs) {
      await resetIntentos();
    }
    if (state.estaBloqueado) return AdminLoginResult.blocked;

    final e = email.trim().toLowerCase();
    final p = password.trim();

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(email: e, password: p);
      if (res.session != null) {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.others);
      }
      final user = res.user ?? Supabase.instance.client.auth.currentUser;
      if (user == null) return AdminLoginResult.invalidCredentials;

      final role = await _roleForUser(user.id);
      if (role != 'admin') {
        return AdminLoginResult.invalidCredentials;
      }

      if (!mounted) return AdminLoginResult.ok;
      final nextOk = state.copyWith(
        adminLogueado: true,
        intentosFallidos: 0,
        bloqueadoHastaEpochMs: 0,
      );
      state = nextOk;
      await _persist(nextOk);
      return AdminLoginResult.ok;
    } on AuthException {
      if (!mounted) return AdminLoginResult.invalidCredentials;
      final nextAttempts = state.intentosFallidos + 1;
      if (nextAttempts >= _maxFailedAttempts) {
        final blockedUntil = DateTime.now().add(_blockDuration).millisecondsSinceEpoch;
        final next = state.copyWith(
          adminLogueado: false,
          intentosFallidos: nextAttempts,
          bloqueadoHastaEpochMs: blockedUntil,
        );
        state = next;
        await _persist(next);
        return AdminLoginResult.blocked;
      }

      final next = state.copyWith(
        adminLogueado: false,
        intentosFallidos: nextAttempts,
      );
      state = next;
      await _persist(next);
      return AdminLoginResult.invalidCredentials;
    }
  }

  Future<void> logout() async {
    state = AdminAuthState.initial;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedKey);
    await prefs.remove(_failedKey);
    await prefs.remove(_blockedUntilKey);
  }

  Future<void> resetIntentos() async {
    final next = state.copyWith(
      intentosFallidos: 0,
      bloqueadoHastaEpochMs: 0,
    );
    state = next;
    await _persist(next);
  }

  Future<String?> _roleForUser(String userId) async {
    final row = await Supabase.instance.client.from('profiles').select('role').eq('id', userId).maybeSingle();
    return row?['role']?.toString();
  }
}

final adminAuthProvider = StateNotifierProvider<AdminAuthController, AdminAuthState>(
  (ref) => AdminAuthController(),
);
