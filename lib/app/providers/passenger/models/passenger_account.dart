import 'payment_method.dart';
import '../../../../data/models/app_role.dart';

class PassengerAccount {
  static const _unset = Object();

  const PassengerAccount({
    required this.id,
    required this.role,
    required this.isBlocked,
    required this.hasActiveReservation,
    this.name,
    this.email,
    this.phone,
    this.dni,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.preferredPickup,
    this.savedPaymentMethod,
  });

  final String id;
  final AppRole role;
  final String? name;
  final String? email;
  final String? phone;
  final String? dni;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? preferredPickup;
  final PaymentMethod? savedPaymentMethod;
  final bool isBlocked;
  final bool hasActiveReservation;

  PassengerAccount copyWith({
    String? id,
    AppRole? role,
    String? name,
    String? email,
    String? phone,
    String? dni,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    Object? preferredPickup = _unset,
    Object? savedPaymentMethod = _unset,
    bool? isBlocked,
    bool? hasActiveReservation,
  }) {
    return PassengerAccount(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dni: dni ?? this.dni,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      preferredPickup: preferredPickup == _unset ? this.preferredPickup : preferredPickup as String?,
      savedPaymentMethod: savedPaymentMethod == _unset
          ? this.savedPaymentMethod
          : savedPaymentMethod as PaymentMethod?,
      isBlocked: isBlocked ?? this.isBlocked,
      hasActiveReservation: hasActiveReservation ?? this.hasActiveReservation,
    );
  }
}
