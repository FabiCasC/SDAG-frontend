import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_method.dart';
import '../repositories/passenger_account_repository.dart';
import 'connectivity_controller.dart';
import 'passenger_session_controller.dart';

class PassengerPaymentMethodsState {
  const PassengerPaymentMethodsState({
    required this.isLoading,
    required this.isSaving,
    required this.method,
  });

  final bool isLoading;
  final bool isSaving;
  final PaymentMethod? method;

  PassengerPaymentMethodsState copyWith({
    bool? isLoading,
    bool? isSaving,
    PaymentMethod? method,
  }) {
    return PassengerPaymentMethodsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      method: method,
    );
  }

  static PassengerPaymentMethodsState initial() =>
      const PassengerPaymentMethodsState(isLoading: true, isSaving: false, method: null);
}

final passengerPaymentMethodsControllerProvider = StateNotifierProvider.autoDispose<
    PassengerPaymentMethodsController, PassengerPaymentMethodsState>((ref) {
  return PassengerPaymentMethodsController(ref: ref)..load();
});

class PassengerPaymentMethodsController
    extends StateNotifier<PassengerPaymentMethodsState> {
  PassengerPaymentMethodsController({required this.ref})
      : super(PassengerPaymentMethodsState.initial());

  final Ref ref;

  PassengerAccountRepository get _repo =>
      ref.read(passengerAccountRepositoryProvider);

  String? get _accountId => ref.read(passengerSessionProvider).account?.id;

  bool get _isOnline => ref.read(connectivityProvider);

  Future<void> load() async {
    final accountId = _accountId;
    if (accountId == null) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      return;
    }
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    final method = await _repo.getSavedPaymentMethod(accountId: accountId);
    if (!mounted) return;
    state = PassengerPaymentMethodsState(isLoading: false, isSaving: false, method: method);
  }

  Future<String?> addMethod({
    required PaymentBrand brand,
    required String last4,
    required bool saveForFuture,
  }) async {
    final accountId = _accountId;
    if (accountId == null) return 'No existe una cuenta asociada';
    if (!_isOnline) return 'Sin conexión';
    if (state.isSaving) return null;

    if (!mounted) return null;
    state = state.copyWith(isSaving: true);
    try {
      final method = await _repo.savePaymentMethod(
        accountId: accountId,
        brand: brand,
        last4: last4,
        saveForFuture: saveForFuture,
      );
      if (!mounted) return null;
      state = PassengerPaymentMethodsState(isLoading: false, isSaving: false, method: method);
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  Future<String?> toggleSaveForFuture(bool enabled) async {
    final accountId = _accountId;
    final current = state.method;
    if (accountId == null) return 'No existe una cuenta asociada';
    if (current == null) return null;
    if (!_isOnline) return 'Sin conexión';
    if (state.isSaving) return null;

    if (!mounted) return null;
    state = state.copyWith(isSaving: true);
    try {
      final updated = await _repo.updatePaymentMethod(
        accountId: accountId,
        method: current.copyWith(saveForFuture: enabled),
      );
      if (!mounted) return null;
      state = state.copyWith(method: updated, isSaving: false);
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  Future<String?> replaceWithPreset(PaymentMethod preset) async {
    final accountId = _accountId;
    if (accountId == null) return 'No existe una cuenta asociada';
    if (!_isOnline) return 'Sin conexión';
    if (state.isSaving) return null;

    if (!mounted) return null;
    state = state.copyWith(isSaving: true);
    try {
      final updated = await _repo.updatePaymentMethod(
        accountId: accountId,
        method: preset,
      );
      if (!mounted) return null;
      state = state.copyWith(method: updated, isSaving: false);
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  Future<String?> delete() async {
    final accountId = _accountId;
    if (accountId == null) return 'No existe una cuenta asociada';
    if (state.isSaving) return null;

    if (!mounted) return null;
    state = state.copyWith(isSaving: true);
    try {
      await _repo.deletePaymentMethod(accountId: accountId);
      if (!mounted) return null;
      state = PassengerPaymentMethodsState(isLoading: false, isSaving: false, method: null);
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }
}

