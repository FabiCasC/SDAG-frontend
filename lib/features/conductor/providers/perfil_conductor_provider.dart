import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conductor_voice_provider.dart';

class PerfilConductorState {
  const PerfilConductorState({
    required this.telefono,
    required this.pushEnabled,
    required this.photoVersion,
  });

  final String telefono;
  final bool pushEnabled;
  final int photoVersion;

  PerfilConductorState copyWith({
    String? telefono,
    bool? pushEnabled,
    int? photoVersion,
  }) {
    return PerfilConductorState(
      telefono: telefono ?? this.telefono,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      photoVersion: photoVersion ?? this.photoVersion,
    );
  }

  static const initial = PerfilConductorState(
    telefono: '',
    pushEnabled: true,
    photoVersion: 0,
  );
}

class PerfilConductorController extends StateNotifier<PerfilConductorState> {
  PerfilConductorController(this.ref) : super(PerfilConductorState.initial) {
    _load();
  }

  final Ref ref;

  static const _telefonoKey = 'sdag_conductor_phone';
  static const _pushKey = 'sdag_conductor_push_enabled';
  static const _photoKey = 'sdag_conductor_photo_version';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      telefono: prefs.getString(_telefonoKey) ?? '',
      pushEnabled: prefs.getBool(_pushKey) ?? true,
      photoVersion: prefs.getInt(_photoKey) ?? 0,
    );
  }

  Future<bool> updateTelefono(String value) async {
    final v = value.trim();
    final isValid = RegExp(r'^\d{9}$').hasMatch(v);
    if (!isValid) return false;
    state = state.copyWith(telefono: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_telefonoKey, v);
    return true;
  }

  Future<void> updateFoto() async {
    final next = state.photoVersion + 1;
    state = state.copyWith(photoVersion: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_photoKey, next);
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final current = currentPassword.trim();
    final next = newPassword.trim();
    final confirm = confirmPassword.trim();

    if (next.length < 6) return false;
    if (next != confirm) return false;

    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: current,
      );
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: next));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleVoz(bool enabled) async {
    await ref.read(conductorVoiceProvider.notifier).setEnabled(enabled);
  }

  Future<void> togglePush(bool enabled) async {
    state = state.copyWith(pushEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, enabled);
  }
}

final perfilConductorProvider =
    StateNotifierProvider<PerfilConductorController, PerfilConductorState>(
  (ref) => PerfilConductorController(ref),
);

