import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    required this.originalPickup,
    required this.name,
    required this.email,
    required this.phone,
    required this.pickup,
    required this.emailError,
    required this.phoneError,
    required this.pickupError,
    required this.metodoPago,
  });

  final bool isLoading;
  final bool isSaving;

  final String originalName;
  final String originalEmail;
  final String originalPhone;
  final String originalPickup;

  final String name;
  final String email;
  final String phone;
  final String pickup;

  final String? emailError;
  final String? phoneError;
  final String? pickupError;

  final PerfilMetodoPago? metodoPago;

  bool get hasChanges =>
      name.trim() != originalName.trim() ||
      email.trim() != originalEmail.trim() ||
      phone.trim() != originalPhone.trim() ||
      pickup.trim() != originalPickup.trim();

  bool get isValid =>
      emailError == null && phoneError == null && pickupError == null;

  PerfilState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? originalName,
    String? originalEmail,
    String? originalPhone,
    String? originalPickup,
    String? name,
    String? email,
    String? phone,
    String? pickup,
    String? emailError,
    String? phoneError,
    String? pickupError,
    PerfilMetodoPago? metodoPago,
    bool clearMetodoPago = false,
  }) {
    return PerfilState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      originalName: originalName ?? this.originalName,
      originalEmail: originalEmail ?? this.originalEmail,
      originalPhone: originalPhone ?? this.originalPhone,
      originalPickup: originalPickup ?? this.originalPickup,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      pickup: pickup ?? this.pickup,
      emailError: emailError,
      phoneError: phoneError,
      pickupError: pickupError,
      metodoPago: clearMetodoPago ? null : (metodoPago ?? this.metodoPago),
    );
  }

  static const empty = PerfilState(
    isLoading: true,
    isSaving: false,
    originalName: '',
    originalEmail: '',
    originalPhone: '',
    originalPickup: '',
    name: '',
    email: '',
    phone: '',
    pickup: '',
    emailError: null,
    phoneError: null,
    pickupError: null,
    metodoPago: null,
  );
}

class PerfilController extends StateNotifier<PerfilState> {
  PerfilController({required this.ref}) : super(PerfilState.empty) {
    _load();
  }

  final Ref ref;

  static const _prefsNameKey = 'sdag_profile_name';
  static const _prefsEmailKey = 'sdag_profile_email';
  static const _prefsPhoneKey = 'sdag_profile_phone';
  static const _prefsPickupKey = 'sdag_profile_pickup';

  static const _prefsPaymentTypeKey = 'sdag_payment_type';
  static const _prefsPaymentLast4Key = 'sdag_payment_last4';

  Future<void> _load() async {
    final session = ref.read(passengerSessionProvider);
    final account = session.account;
    final prefs = await SharedPreferences.getInstance();

    final id = account?.id ?? 'anon';
    final name = prefs.getString('$_prefsNameKey/$id') ?? (account?.name ?? '');
    final email = prefs.getString('$_prefsEmailKey/$id') ?? (account?.email ?? '');
    final phone = prefs.getString('$_prefsPhoneKey/$id') ?? (account?.phone ?? '');
    final pickup = prefs.getString('$_prefsPickupKey/$id') ?? (account?.preferredPickup ?? '');

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
      originalPickup: pickup,
      name: name,
      email: email,
      phone: phone,
      pickup: pickup,
      emailError: _emailError(email: email, originalEmail: email),
      phoneError: _phoneError(phone),
      pickupError: _pickupError(pickup),
      metodoPago: metodoPago,
    );
  }

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

  void setPickup(String value) {
    state = state.copyWith(
      pickup: value,
      pickupError: _pickupError(value),
    );
  }

  Future<void> updatePerfil() async {
    if (!state.hasChanges || !state.isValid) return;

    state = state.copyWith(isSaving: true);
    await Future<void>.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final sessionCtrl = ref.read(passengerSessionProvider.notifier);
    final current = ref.read(passengerSessionProvider).account;
    final id = current?.id ?? 'anon';

    await prefs.setString('$_prefsNameKey/$id', state.name.trim());
    await prefs.setString('$_prefsEmailKey/$id', state.email.trim());
    await prefs.setString('$_prefsPhoneKey/$id', _digitsOnly(state.phone));
    await prefs.setString('$_prefsPickupKey/$id', state.pickup.trim());

    if (current != null) {
      final updated = current.copyWith(
        name: state.name.trim(),
        email: state.email.trim(),
        phone: _digitsOnly(state.phone),
        preferredPickup: state.pickup.trim().isEmpty ? null : state.pickup.trim(),
      );
      sessionCtrl.state = sessionCtrl.state.copyWith(account: updated);
    }

    state = state.copyWith(
      isSaving: false,
      originalName: state.name.trim(),
      originalEmail: state.email.trim(),
      originalPhone: _digitsOnly(state.phone),
      originalPickup: state.pickup.trim(),
    );
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
