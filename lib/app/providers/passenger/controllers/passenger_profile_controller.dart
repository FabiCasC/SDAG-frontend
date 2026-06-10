import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/app_role.dart';
import '../models/passenger_account.dart';
import '../repositories/passenger_account_repository.dart';
import '../validators/passenger_auth_validators.dart';
import 'passenger_session_controller.dart';

class PassengerProfileState {
  const PassengerProfileState({
    required this.isSaving,
    required this.name,
    required this.email,
    required this.phone,
    required this.preferredPickup,
    required this.nameError,
    required this.emailError,
    required this.phoneError,
    required this.pickupError,
  });

  final bool isSaving;
  final String name;
  final String email;
  final String phone;
  final String preferredPickup;

  final String? nameError;
  final String? emailError;
  final String? phoneError;
  final String? pickupError;

  PassengerProfileState copyWith({
    bool? isSaving,
    String? name,
    String? email,
    String? phone,
    String? preferredPickup,
    String? nameError,
    String? emailError,
    String? phoneError,
    String? pickupError,
  }) {
    return PassengerProfileState(
      isSaving: isSaving ?? this.isSaving,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      preferredPickup: preferredPickup ?? this.preferredPickup,
      nameError: nameError,
      emailError: emailError,
      phoneError: phoneError,
      pickupError: pickupError,
    );
  }

  static PassengerProfileState fromAccount(PassengerAccount account) {
    return PassengerProfileState(
      isSaving: false,
      name: account.name ?? '',
      email: account.email ?? '',
      phone: account.phone ?? '',
      preferredPickup: account.preferredPickup ?? '',
      nameError: null,
      emailError: null,
      phoneError: null,
      pickupError: null,
    );
  }
}

final passengerProfileControllerProvider = StateNotifierProvider.autoDispose<
    PassengerProfileController, PassengerProfileState?>((ref) {
  final sessionAccount = ref.watch(passengerSessionProvider).account;
  final authId = Supabase.instance.client.auth.currentUser?.id;
  if (sessionAccount == null && authId == null) {
    return PassengerProfileController.empty(ref);
  }
  final id = sessionAccount?.id ?? authId!;
  final seed = sessionAccount ??
      PassengerAccount(
        id: id,
        role: AppRole.passenger,
        isBlocked: false,
        hasActiveReservation: false,
      );
  return PassengerProfileController(ref: ref, account: seed);
});

class PassengerProfileController
    extends StateNotifier<PassengerProfileState?> {
  PassengerProfileController({
    required this.ref,
    required PassengerAccount account,
  }) : super(PassengerProfileState.fromAccount(account));

  PassengerProfileController.empty(this.ref) : super(null);

  final Ref ref;

  PassengerAccountRepository get _repo =>
      ref.read(passengerAccountRepositoryProvider);

  PassengerAccount? get _account => ref.read(passengerSessionProvider).account;

  /// Perfil siempre desde `auth.currentUser` + fila en `profiles` (evita caché obsoleto).
  Future<void> loadFromAuthProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || state == null) return;
    try {
      final account = await _repo.getAccountById(userId);
      if (!mounted) return;
      ref.read(passengerSessionProvider.notifier).state =
          PassengerSessionState(isLoading: false, account: account);
      state = PassengerProfileState.fromAccount(account);
    } catch (_) {
      // Sin red o RLS: no pisar el formulario
    }
  }

  void setName(String value) {
    if (state == null) return;
    state = state!.copyWith(name: value, nameError: null);
  }

  void setEmail(String value) {
    if (state == null) return;
    final error = value.trim().isEmpty
        ? null
        : (PassengerAuthValidators.isValidEmail(value) ? null : 'Correo inválido');
    state = state!.copyWith(email: value, emailError: error);
  }

  void setPhone(String value) {
    if (state == null) return;
    final error = value.trim().isEmpty
        ? null
        : (PassengerAuthValidators.isValidPeruPhone(value) ? null : 'Teléfono inválido');
    state = state!.copyWith(phone: value, phoneError: error);
  }

  void setPreferredPickup(String value) {
    if (state == null) return;
    state = state!.copyWith(preferredPickup: value, pickupError: null);
  }

  bool _validate() {
    final s = state;
    if (s == null) return false;

    final nameError = s.name.trim().length >= 3 ? null : 'Campo vacío';
    final emailError = PassengerAuthValidators.isValidEmail(s.email) ? null : 'Correo inválido';
    final phoneError = PassengerAuthValidators.isValidPeruPhone(s.phone) ? null : 'Teléfono inválido';

    String? pickupError;
    final pickup = s.preferredPickup.trim();
    if (pickup.isNotEmpty && pickup.length < 3) {
      pickupError = 'Mínimo 3 caracteres';
    }

    state = s.copyWith(
      nameError: nameError,
      emailError: emailError,
      phoneError: phoneError,
      pickupError: pickupError,
    );

    return nameError == null && emailError == null && phoneError == null && pickupError == null;
  }

  Future<String?> save() async {
    final s = state;
    final account = _account;
    if (s == null || account == null) return 'No existe una cuenta asociada';
    if (s.isSaving) return null;
    if (!_validate()) return null;

    if (!mounted) return null;
    state = s.copyWith(isSaving: true);
    try {
      final updated = await _repo.updateProfile(
        accountId: account.id,
        name: s.name,
        email: s.email,
        phone: s.phone,
        preferredPickup: s.preferredPickup.trim().isEmpty ? null : s.preferredPickup.trim(),
      );
      if (!mounted) return null;
      ref.read(passengerSessionProvider.notifier).state =
          PassengerSessionState(isLoading: false, account: updated);
      state = PassengerProfileState.fromAccount(updated);
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted && state != null) {
        state = state!.copyWith(isSaving: false);
      }
    }
  }

  Future<String?> deletePreferredPickup() async {
    final s = state;
    final account = _account;
    if (s == null || account == null) return 'No existe una cuenta asociada';
    if (s.isSaving) return null;

    if (!mounted) return null;
    state = s.copyWith(isSaving: true);
    try {
      final updated = await _repo.updateProfile(
        accountId: account.id,
        name: s.name,
        email: s.email,
        phone: s.phone,
        preferredPickup: null,
      );
      if (!mounted) return null;
      ref.read(passengerSessionProvider.notifier).state =
          PassengerSessionState(isLoading: false, account: updated);
      state = PassengerProfileState.fromAccount(updated);
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted && state != null) {
        state = state!.copyWith(isSaving: false);
      }
    }
  }
}

