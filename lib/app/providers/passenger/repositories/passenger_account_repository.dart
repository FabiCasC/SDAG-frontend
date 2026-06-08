import '../models/passenger_account.dart';
import '../models/payment_method.dart';

sealed class PassengerAuthFailure implements Exception {
  const PassengerAuthFailure(this.message);
  final String message;
}

class GenericPassengerAuthFailure extends PassengerAuthFailure {
  const GenericPassengerAuthFailure(super.message);
}

class InvalidCredentialsFailure extends PassengerAuthFailure {
  const InvalidCredentialsFailure() : super('Credenciales incorrectas');
}

class AccountBlockedFailure extends PassengerAuthFailure {
  const AccountBlockedFailure()
      : super('La cuenta está temporalmente bloqueada');
}

class EmailAlreadyRegisteredFailure extends PassengerAuthFailure {
  const EmailAlreadyRegisteredFailure() : super('Correo ya registrado');
}

class PhoneAlreadyRegisteredFailure extends PassengerAuthFailure {
  const PhoneAlreadyRegisteredFailure() : super('Teléfono ya registrado');
}

class DniAlreadyRegisteredFailure extends PassengerAuthFailure {
  const DniAlreadyRegisteredFailure() : super('DNI ya registrado');
}

class InvalidPhoneFailure extends PassengerAuthFailure {
  const InvalidPhoneFailure() : super('Teléfono inválido');
}

class AccountNotFoundFailure extends PassengerAuthFailure {
  const AccountNotFoundFailure() : super('No existe una cuenta asociada');
}

class ExpiredTokenFailure extends PassengerAuthFailure {
  const ExpiredTokenFailure() : super('El enlace expiró');
}

class InvalidVerificationCodeFailure extends PassengerAuthFailure {
  const InvalidVerificationCodeFailure() : super('Código inválido');
}

class PaymentGatewayFailure extends PassengerAuthFailure {
  const PaymentGatewayFailure()
      : super('No pudimos guardar tu método de pago');
}

class DuplicateEmailFailure extends PassengerAuthFailure {
  const DuplicateEmailFailure() : super('Correo duplicado');
}

class PassengerPasswordResetSession {
  const PassengerPasswordResetSession({
    required this.identifier,
    required this.code,
    required this.createdAt,
  });

  final String identifier;
  final String code;
  final DateTime createdAt;
}

abstract interface class PassengerAccountRepository {
  Future<PassengerAccount> login({
    required String identifier,
    required String password,
  });

  Future<PassengerAccount> registerWithEmail({
    required String email,
    required String dni,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String phone,
    required String password,
  });

  Future<PassengerPasswordResetSession> startPasswordReset({
    required String identifier,
  });

  Future<void> verifyPasswordResetCode({
    required PassengerPasswordResetSession session,
    required String code,
  });

  Future<void> completePasswordReset({
    required PassengerPasswordResetSession session,
    required String newPassword,
  });

  Future<PassengerAccount> getAccountById(String id);

  Future<PassengerAccount> updateProfile({
    required String accountId,
    required String name,
    required String email,
    required String phone,
    required String? preferredPickup,
  });

  Future<PaymentMethod?> getSavedPaymentMethod({required String accountId});

  Future<PaymentMethod> savePaymentMethod({
    required String accountId,
    required PaymentBrand brand,
    required String last4,
    required bool saveForFuture,
  });

  Future<PaymentMethod> updatePaymentMethod({
    required String accountId,
    required PaymentMethod method,
  });

  Future<void> deletePaymentMethod({required String accountId});
}
