import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/passenger_account_repository.dart';
import '../validators/passenger_auth_validators.dart';
import 'passenger_session_controller.dart';

enum ForgotPasswordStep {
  identifier,
  code,
  newPassword,
  done,
}

class PassengerForgotPasswordState {
  const PassengerForgotPasswordState({
    required this.step,
    required this.identifier,
    required this.code,
    required this.newPassword,
    required this.confirmPassword,
    required this.identifierError,
    required this.codeError,
    required this.passwordError,
    required this.confirmPasswordError,
    required this.isLoading,
    required this.resetSession,
  });

  final ForgotPasswordStep step;
  final String identifier;
  final String code;
  final String newPassword;
  final String confirmPassword;
  final String? identifierError;
  final String? codeError;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool isLoading;
  final PassengerPasswordResetSession? resetSession;

  PassengerForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    String? identifier,
    String? code,
    String? newPassword,
    String? confirmPassword,
    String? identifierError,
    String? codeError,
    String? passwordError,
    String? confirmPasswordError,
    bool? isLoading,
    PassengerPasswordResetSession? resetSession,
  }) {
    return PassengerForgotPasswordState(
      step: step ?? this.step,
      identifier: identifier ?? this.identifier,
      code: code ?? this.code,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      identifierError: identifierError,
      codeError: codeError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      isLoading: isLoading ?? this.isLoading,
      resetSession: resetSession ?? this.resetSession,
    );
  }

  static PassengerForgotPasswordState initial() =>
      const PassengerForgotPasswordState(
        step: ForgotPasswordStep.identifier,
        identifier: '',
        code: '',
        newPassword: '',
        confirmPassword: '',
        identifierError: null,
        codeError: null,
        passwordError: null,
        confirmPasswordError: null,
        isLoading: false,
        resetSession: null,
      );
}

final passengerForgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<PassengerForgotPasswordController,
        PassengerForgotPasswordState>((ref) {
  return PassengerForgotPasswordController(ref: ref);
});

class PassengerForgotPasswordController
    extends StateNotifier<PassengerForgotPasswordState> {
  PassengerForgotPasswordController({required this.ref})
      : super(PassengerForgotPasswordState.initial());

  final Ref ref;

  PassengerAccountRepository get _repo =>
      ref.read(passengerAccountRepositoryProvider);

  void setIdentifier(String value) {
    final error = value.trim().isEmpty
        ? null
        : (PassengerAuthValidators.isValidEmail(value) ? null : 'Ingresa un correo válido');
    state = state.copyWith(identifier: value, identifierError: error);
  }

  void setCode(String value) {
    state = state.copyWith(code: value, codeError: null);
  }

  void setNewPassword(String value) {
    state = state.copyWith(newPassword: value, passwordError: null);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, confirmPasswordError: null);
  }

  bool _validateIdentifier() {
    final error =
        PassengerAuthValidators.isValidEmail(state.identifier) ? null : 'Ingresa un correo válido';
    state = state.copyWith(identifierError: error);
    return error == null;
  }

  bool _validateCode() {
    final v = state.code.trim();
    final error = v.length == 6 ? null : 'Código inválido';
    state = state.copyWith(codeError: error);
    return error == null;
  }

  bool _validatePasswords() {
    final pw = state.newPassword.trim();
    final confirm = state.confirmPassword.trim();

    final passwordError = pw.length >= 8 ? null : 'Mínimo 8 caracteres';
    final confirmError =
        confirm == pw ? null : 'Las contraseñas no coinciden';

    state = state.copyWith(
      passwordError: passwordError,
      confirmPasswordError: confirmError,
    );
    return passwordError == null && confirmError == null;
  }

  Future<String?> submitIdentifier() async {
    if (state.isLoading) return null;
    if (!_validateIdentifier()) return null;

    if (!mounted) return null;
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repo.startPasswordReset(identifier: state.identifier);
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        step: ForgotPasswordStep.code,
        resetSession: session,
      );
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<String?> submitCode() async {
    if (state.isLoading) return null;
    if (!_validateCode()) return null;
    final session = state.resetSession;
    if (session == null) return 'El enlace expiró';

    if (!mounted) return null;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.verifyPasswordResetCode(session: session, code: state.code);
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, step: ForgotPasswordStep.newPassword);
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<String?> submitNewPassword() async {
    if (state.isLoading) return null;
    if (!_validatePasswords()) return null;
    final session = state.resetSession;
    if (session == null) return 'El enlace expiró';

    if (!mounted) return null;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.completePasswordReset(session: session, newPassword: state.newPassword.trim());
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, step: ForgotPasswordStep.done);
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void restart() {
    state = PassengerForgotPasswordState.initial();
  }
}
