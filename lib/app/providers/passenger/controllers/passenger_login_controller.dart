import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/passenger_account_repository.dart';
import '../validators/passenger_auth_validators.dart';
import 'passenger_session_controller.dart';

class PassengerLoginState {
  const PassengerLoginState({
    required this.identifier,
    required this.password,
    required this.identifierError,
    required this.passwordError,
    required this.isSubmitting,
  });

  final String identifier;
  final String password;
  final String? identifierError;
  final String? passwordError;
  final bool isSubmitting;

  PassengerLoginState copyWith({
    String? identifier,
    String? password,
    String? identifierError,
    String? passwordError,
    bool? isSubmitting,
  }) {
    return PassengerLoginState(
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
      identifierError: identifierError,
      passwordError: passwordError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  static PassengerLoginState initial() => const PassengerLoginState(
        identifier: '',
        password: '',
        identifierError: null,
        passwordError: null,
        isSubmitting: false,
      );
}

final passengerLoginControllerProvider = StateNotifierProvider.autoDispose<
    PassengerLoginController, PassengerLoginState>((ref) {
  return PassengerLoginController(ref: ref);
});

class PassengerLoginController extends StateNotifier<PassengerLoginState> {
  PassengerLoginController({required this.ref}) : super(PassengerLoginState.initial());

  final Ref ref;

  void setIdentifier(String value) {
    final error = value.trim().isEmpty
        ? null
        : (PassengerAuthValidators.isValidEmail(value)
            ? null
            : 'Ingresa un correo válido');
    state = state.copyWith(
      identifier: value,
      identifierError: error,
    );
  }

  void setPassword(String value) {
    state = state.copyWith(
      password: value,
      passwordError: null,
    );
  }

  bool _validate() {
    final id = state.identifier.trim();
    final pw = state.password;

    final identifierError =
        PassengerAuthValidators.isValidEmail(id) ? null : 'Ingresa un correo válido';
    final passwordError = pw.trim().isEmpty ? 'Contraseña requerida' : null;

    state = state.copyWith(
      identifierError: identifierError,
      passwordError: passwordError,
    );

    return identifierError == null && passwordError == null;
  }

  Future<String?> submit() async {
    try {
      if (state.isSubmitting) return null;
      if (!_validate()) return null;

      if (!mounted) return null;
      state = state.copyWith(isSubmitting: true);

      final identifier = state.identifier;
      final password = state.password;
      await ref.read(passengerSessionProvider.notifier).login(
            identifier: identifier,
            password: password,
          );

      if (!mounted) return null;
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } catch (_) {
      return 'Credenciales incorrectas';
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }
}
