import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../app/providers/passenger/validators/passenger_auth_validators.dart';

class PerfilMetodoPago {
  const PerfilMetodoPago({required this.type, required this.last4});

  final String type;
  final String last4;

  String get label {
    final t = type.toLowerCase() == 'yape' ? 'Yape' : 'Tarjeta';
    return '$t ****$last4';
  }
}

class PerfilState {
  const PerfilState({
    required this.isLoading,
    required this.isSaving,
    required this.originalName,
    required this.originalEmail,
    required this.originalPhone,
    required this.originalDni,
    required this.originalPickup,
    required this.name,
    required this.email,
    required this.phone,
    required this.dni,
    required this.pickup,
    required this.emailError,
    required this.phoneError,
    required this.dniError,
    required this.pickupError,
    required this.metodoPago,
    required this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;

  final String originalName;
  final String originalEmail;
  final String originalPhone;
  final String originalDni;
  final String originalPickup;

  final String name;
  final String email;
  final String phone;
  final String dni;
  final String pickup;

  final String? emailError;
  final String? phoneError;
  final String? dniError;
  final String? pickupError;

  final PerfilMetodoPago? metodoPago;
  final String? errorMessage;

  bool get hasChanges =>
      name.trim() != originalName.trim() ||
      email.trim() != originalEmail.trim() ||
      phone.trim() != originalPhone.trim() ||
      dni.trim() != originalDni.trim() ||
      pickup.trim() != originalPickup.trim();

  bool get isValid =>
      emailError == null && phoneError == null && dniError == null && pickupError == null;

  PerfilState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? originalName,
    String? originalEmail,
    String? originalPhone,
    String? originalDni,
    String? originalPickup,
    String? name,
    String? email,
    String? phone,
    String? dni,
    String? pickup,
    String? emailError,
    String? phoneError,
    String? dniError,
    String? pickupError,
    PerfilMetodoPago? metodoPago,
    String? errorMessage,
    bool clearMetodoPago = false,
  }) {
    return PerfilState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      originalName: originalName ?? this.originalName,
      originalEmail: originalEmail ?? this.originalEmail,
      originalPhone: originalPhone ?? this.originalPhone,
      originalDni: originalDni ?? this.originalDni,
      originalPickup: originalPickup ?? this.originalPickup,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dni: dni ?? this.dni,
      pickup: pickup ?? this.pickup,
      emailError: emailError,
      phoneError: phoneError,
      dniError: dniError,
      pickupError: pickupError,
      metodoPago: clearMetodoPago ? null : (metodoPago ?? this.metodoPago),
      errorMessage: errorMessage,
    );
  }

  static const empty = PerfilState(
    isLoading: true,
    isSaving: false,
    originalName: '',
    originalEmail: '',
    originalPhone: '',
    originalDni: '',
    originalPickup: '',
    name: '',
    email: '',
    phone: '',
    dni: '',
    pickup: '',
    emailError: null,
    phoneError: null,
    dniError: null,
    pickupError: null,
    metodoPago: null,
    errorMessage: null,
  );
}

class PerfilController extends StateNotifier<PerfilState> {
  PerfilController({required this.ref}) : super(PerfilState.empty) {
    _load();
  }

  final Ref ref;

  static const _prefsPaymentTypeKey = 'sdag_payment_type';
  static const _prefsPaymentLast4Key = 'sdag_payment_last4';

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        state = PerfilState.empty.copyWith(
          isLoading: false,
          errorMessage: 'No hay una sesion activa.',
        );
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final name = profile['name']?.toString() ?? '';
      final email = profile['email']?.toString() ?? '';
      final phone = profile['phone']?.toString() ?? '';
      final dni = profile['dni']?.toString() ?? '';
      final pickup = profile['preferred_pickup']?.toString() ?? '';

      final payType = prefs.getString(_prefsPaymentTypeKey);
      final payLast4 = prefs.getString(_prefsPaymentLast4Key);
      final metodoPago =
          (payType != null && payLast4 != null) ? PerfilMetodoPago(type: payType, last4: payLast4) : null;

      state = PerfilState(
        isLoading: false,
        isSaving: false,
        originalName: name,
        originalEmail: email,
        originalPhone: phone,
        originalDni: dni,
        originalPickup: pickup,
        name: name,
        email: email,
        phone: phone,
        dni: dni,
        pickup: pickup,
        emailError: _emailError(email: email, originalEmail: email),
        phoneError: _phoneError(phone),
        dniError: _dniError(dni),
        pickupError: _pickupError(pickup),
        metodoPago: metodoPago,
        errorMessage: null,
      );
    } catch (e) {
      state = PerfilState.empty.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar tu perfil: $e',
      );
    }
  }

  Future<void> reload() => _load();

  void setName(String value) {
    state = state.copyWith(name: value);
  }

  void setEmail(String value) {
    final normalized = value.trim();
    state = state.copyWith(
      email: value,
      emailError: _emailError(email: normalized, originalEmail: state.originalEmail),
    );
  }

  void setPhone(String value) {
    state = state.copyWith(
      phone: value,
      phoneError: _phoneError(value),
    );
  }

  void setDni(String value) {
    state = state.copyWith(
      dni: value,
      dniError: _dniError(value),
    );
  }

  void setPickup(String value) {
    state = state.copyWith(
      pickup: value,
      pickupError: _pickupError(value),
    );
  }

  Future<bool> updatePerfil() async {
    if (!state.hasChanges || !state.isValid) return false;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No hay una sesion activa.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      await Supabase.instance.client.from('profiles').update({
        'name': state.name.trim(),
        'email': state.email.trim().toLowerCase(),
        'phone': _digitsOnly(state.phone),
        'dni': _digitsOnly(state.dni),
        'preferred_pickup': state.pickup.trim().isEmpty ? null : state.pickup.trim(),
      }).eq('id', userId);

      final sessionCtrl = ref.read(passengerSessionProvider.notifier);
      final current = ref.read(passengerSessionProvider).account;
      if (current != null) {
        final updated = current.copyWith(
          name: state.name.trim(),
          email: state.email.trim().toLowerCase(),
          phone: _digitsOnly(state.phone),
          dni: _digitsOnly(state.dni),
          preferredPickup: state.pickup.trim().isEmpty ? null : state.pickup.trim(),
        );
        sessionCtrl.state = sessionCtrl.state.copyWith(account: updated);
      }

      state = state.copyWith(
        isSaving: false,
        originalName: state.name.trim(),
        originalEmail: state.email.trim().toLowerCase(),
        originalPhone: _digitsOnly(state.phone),
        originalDni: _digitsOnly(state.dni),
        originalPickup: state.pickup.trim(),
        name: state.name.trim(),
        email: state.email.trim().toLowerCase(),
        phone: _digitsOnly(state.phone),
        dni: _digitsOnly(state.dni),
        pickup: state.pickup.trim(),
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

  Future<void> removeMetodoPago() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsPaymentTypeKey);
    await prefs.remove(_prefsPaymentLast4Key);
    state = state.copyWith(clearMetodoPago: true);
  }

  Future<void> setMetodoPago({required String type, required String last4}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPaymentTypeKey, type);
    await prefs.setString(_prefsPaymentLast4Key, last4);
    state = state.copyWith(metodoPago: PerfilMetodoPago(type: type, last4: last4));
  }

  static String? _emailError({required String email, required String originalEmail}) {
    if (email.isEmpty) return 'Ingresa un correo';
    if (!PassengerAuthValidators.isValidEmail(email)) return 'Correo inválido';

    final normalized = email.toLowerCase();
    final original = originalEmail.toLowerCase();
    if (normalized == original) return null;

    const duplicates = <String>{
      'conductor@sdag.pe',
      'admin@sdag.pe',
    };
    if (duplicates.contains(normalized)) return 'Este correo ya está registrado';
    return null;
  }

  static String? _phoneError(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return null;
    if (digits.length != 9) return 'Debe tener 9 dígitos';
    return null;
  }

  static String? _dniError(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return null;
    if (digits.length != 8) return 'Debe tener 8 dígitos';
    return null;
  }

  static String? _pickupError(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    if (v.length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  static String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
}

final perfilProvider = StateNotifierProvider<PerfilController, PerfilState>(
  (ref) => PerfilController(ref: ref),
);
