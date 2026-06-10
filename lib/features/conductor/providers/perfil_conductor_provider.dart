import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conductor_voice_provider.dart';

class PerfilConductorState {
  const PerfilConductorState({
    required this.isLoading,
    required this.isSaving,
    required this.name,
    required this.email,
    required this.dni,
    required this.phone,
    required this.plate,
    required this.vehicleType,
    required this.driverEstado,
    required this.cuentaActiva,
    required this.telefono,
    required this.pushEnabled,
    required this.photoVersion,
    required this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;

  final String name;
  final String email;
  final String dni;
  final String phone;
  final String plate;
  final String vehicleType;
  final String driverEstado;
  final bool cuentaActiva;

  final String telefono;
  final bool pushEnabled;
  final int photoVersion;
  final String? errorMessage;

  PerfilConductorState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? name,
    String? email,
    String? dni,
    String? phone,
    String? plate,
    String? vehicleType,
    String? driverEstado,
    bool? cuentaActiva,
    String? telefono,
    bool? pushEnabled,
    int? photoVersion,
    String? errorMessage,
  }) {
    return PerfilConductorState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      name: name ?? this.name,
      email: email ?? this.email,
      dni: dni ?? this.dni,
      phone: phone ?? this.phone,
      plate: plate ?? this.plate,
      vehicleType: vehicleType ?? this.vehicleType,
      driverEstado: driverEstado ?? this.driverEstado,
      cuentaActiva: cuentaActiva ?? this.cuentaActiva,
      telefono: telefono ?? this.telefono,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      photoVersion: photoVersion ?? this.photoVersion,
      errorMessage: errorMessage,
    );
  }

  static const initial = PerfilConductorState(
    isLoading: true,
    isSaving: false,
    name: '',
    email: '',
    dni: '',
    phone: '',
    plate: '',
    vehicleType: '',
    driverEstado: 'disponible',
    cuentaActiva: true,
    telefono: '',
    pushEnabled: true,
    photoVersion: 0,
    errorMessage: null,
  );
}

class PerfilConductorController extends StateNotifier<PerfilConductorState> {
  PerfilConductorController(this.ref) : super(PerfilConductorState.initial) {
    _load();
  }

  final Ref ref;

  static const _pushKey = 'sdag_conductor_push_enabled';
  static const _photoKey = 'sdag_conductor_photo_version';

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      pushEnabled: prefs.getBool(_pushKey) ?? true,
      photoVersion: prefs.getInt(_photoKey) ?? 0,
    );

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No hay una sesión activa.',
      );
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('*, drivers(*)')
          .eq('id', user.id)
          .single();

      final driver = await Supabase.instance.client
          .from('drivers')
          .select('*, vehicles(*)')
          .eq('profile_id', user.id)
          .maybeSingle();

      String plate = '';
      String vehicleType = '';
      String driverEstado = 'disponible';
      var cuentaActiva = true;
      if (driver != null) {
        plate = driver['plate']?.toString() ?? '';
        vehicleType = driver['vehicle_type']?.toString() ?? '';
        cuentaActiva = (driver['cuenta_activa'] as bool?) ?? true;
        final rawEstado = driver['estado']?.toString();
        driverEstado = rawEstado == 'en_ruta' ? 'en_ruta' : 'disponible';

        final v = driver['vehicles'];
        if ((plate.isEmpty || vehicleType.isEmpty) && v != null) {
          Map<String, dynamic>? vm;
          if (v is Map<String, dynamic>) {
            vm = v;
          } else if (v is Map) {
            vm = v.cast<String, dynamic>();
          } else if (v is List && v.isNotEmpty) {
            final first = v.first;
            if (first is Map<String, dynamic>) vm = first;
            if (first is Map) vm = first.cast<String, dynamic>();
          }
          if (vm != null) {
            plate = plate.isEmpty ? (vm['plate']?.toString() ?? '') : plate;
            vehicleType =
                vehicleType.isEmpty ? (vm['vehicle_type']?.toString() ?? '') : vehicleType;
          }
        }
      }

      final name = profile['name']?.toString() ?? '';
      final phone = profile['phone']?.toString() ?? '';
      final dni = profile['dni']?.toString() ?? '';
      final email = user.email?.toString() ?? (profile['email']?.toString() ?? '');

      state = state.copyWith(
        isLoading: false,
        name: name,
        email: email,
        dni: dni,
        phone: phone,
        telefono: phone,
        plate: plate,
        vehicleType: vehicleType,
        driverEstado: driverEstado,
        cuentaActiva: cuentaActiva,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar tu perfil: $e',
      );
    }
  }

  Future<void> reload() => _load();

  Future<bool> updatePerfil({
    required String name,
    required String phone,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(errorMessage: 'No hay una sesión activa.');
      return false;
    }

    final n = name.trim();
    final p = phone.trim();
    if (n.isEmpty) {
      state = state.copyWith(errorMessage: 'El nombre es obligatorio.');
      return false;
    }
    if (p.isNotEmpty && !RegExp(r'^\d{9}$').hasMatch(p)) {
      state = state.copyWith(errorMessage: 'Teléfono inválido (debe tener 9 dígitos).');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await Supabase.instance.client.from('profiles').update({
        'name': n,
        'phone': p,
      }).eq('id', user.id);

      state = state.copyWith(
        isSaving: false,
        name: n,
        phone: p,
        telefono: p,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No se pudo guardar tu perfil: $e',
      );
      return false;
    }
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

