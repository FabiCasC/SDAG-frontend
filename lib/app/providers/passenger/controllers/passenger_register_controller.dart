import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/passenger_account_repository.dart';
import '../validators/passenger_auth_validators.dart';
import 'passenger_session_controller.dart';

class PassengerRegisterState {
  const PassengerRegisterState({
    required this.email,
    required this.dni,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.phone,
    required this.password,
    required this.emailError,
    required this.dniError,
    required this.firstNameError,
    required this.lastNameError,
    required this.birthDateError,
    required this.phoneError,
    required this.passwordError,
    required this.isSubmitting,
  });

  final String email;
  final String dni;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String phone;
  final String password;
  final String? emailError;
  final String? dniError;
  final String? firstNameError;
  final String? lastNameError;
  final String? birthDateError;
  final String? phoneError;
  final String? passwordError;
  final bool isSubmitting;

  PassengerRegisterState copyWith({
    String? email,
    String? dni,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? phone,
    String? password,
    String? emailError,
    String? dniError,
    String? firstNameError,
    String? lastNameError,
    String? birthDateError,
    String? phoneError,
    String? passwordError,
    bool? isSubmitting,
  }) {
    return PassengerRegisterState(
      email: email ?? this.email,
      dni: dni ?? this.dni,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      emailError: emailError,
      dniError: dniError,
      firstNameError: firstNameError,
      lastNameError: lastNameError,
      birthDateError: birthDateError,
      phoneError: phoneError,
      passwordError: passwordError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  static PassengerRegisterState initial() => const PassengerRegisterState(
        email: '',
        dni: '',
        firstName: '',
        lastName: '',
        birthDate: null,
        phone: '',
        password: '',
        emailError: null,
        dniError: null,
        firstNameError: null,
        lastNameError: null,
        birthDateError: null,
        phoneError: null,
        passwordError: null,
        isSubmitting: false,
      );
}

final passengerRegisterControllerProvider = StateNotifierProvider.autoDispose<
    PassengerRegisterController, PassengerRegisterState>((ref) {
  return PassengerRegisterController(ref: ref);
});

class PassengerRegisterController extends StateNotifier<PassengerRegisterState> {
  PassengerRegisterController({required this.ref})
      : super(PassengerRegisterState.initial());

  final Ref ref;

  void setEmail(String value) {
    final error = value.trim().isEmpty
        ? null
        : (PassengerAuthValidators.isValidEmail(value) ? null : 'Correo inválido');
    state = state.copyWith(email: value, emailError: error);
  }

  void setDni(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final error = digits.isEmpty
        ? null
        : (digits.length == 8 ? null : 'DNI inválido');
    state = state.copyWith(dni: value, dniError: error);
  }

  void setFirstName(String value) {
    final error = value.trim().isEmpty ? null : (value.trim().length >= 2 ? null : 'Nombre inválido');
    state = state.copyWith(firstName: value, firstNameError: error);
  }

  void setLastName(String value) {
    final error = value.trim().isEmpty ? null : (value.trim().length >= 2 ? null : 'Apellidos inválidos');
    state = state.copyWith(lastName: value, lastNameError: error);
  }

  void setBirthDate(DateTime value) {
    state = state.copyWith(birthDate: value, birthDateError: null);
  }

  void setPhone(String value) {
    final error = value.trim().isEmpty
        ? null
        : (PassengerAuthValidators.isValidPeruPhone(value) ? null : 'Teléfono inválido');
    state = state.copyWith(phone: value, phoneError: error);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, passwordError: null);
  }

  bool _validate() {
    final emailError = PassengerAuthValidators.isValidEmail(state.email) ? null : 'Correo inválido';
    final dniDigits = state.dni.replaceAll(RegExp(r'\D'), '');
    final dniError = dniDigits.length == 8 ? null : 'DNI inválido';
    final firstNameError = state.firstName.trim().length >= 2 ? null : 'Nombre inválido';
    final lastNameError = state.lastName.trim().length >= 2 ? null : 'Apellidos inválidos';
    final birthDateError = state.birthDate == null ? 'Fecha requerida' : null;
    final phoneError =
        PassengerAuthValidators.isValidPeruPhone(state.phone) ? null : 'Teléfono inválido';
    final passwordError = state.password.trim().length >= 8 ? null : 'Mínimo 8 caracteres';

    state = state.copyWith(
      emailError: emailError,
      dniError: dniError,
      firstNameError: firstNameError,
      lastNameError: lastNameError,
      birthDateError: birthDateError,
      phoneError: phoneError,
      passwordError: passwordError,
    );

    return emailError == null &&
        dniError == null &&
        firstNameError == null &&
        lastNameError == null &&
        birthDateError == null &&
        phoneError == null &&
        passwordError == null;
  }

  Future<String?> submit() async {
    if (state.isSubmitting) return null;
    if (!_validate()) return null;

    if (!mounted) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      await ref.read(passengerSessionProvider.notifier).registerWithEmail(
            email: state.email,
            dni: state.dni,
            firstName: state.firstName,
            lastName: state.lastName,
            birthDate: state.birthDate!,
            phone: state.phone,
            password: state.password,
          );
      return null;
    } on PassengerAuthFailure catch (e) {
      return e.message;
    } catch (_) {
      return 'No pudimos completar el registro';
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }
}
