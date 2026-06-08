import 'dart:math';

import '../models/passenger_account.dart';
import '../models/payment_method.dart';
import '../validators/passenger_auth_validators.dart';
import 'passenger_account_repository.dart';
import '../../../../data/models/app_role.dart';

class PassengerAccountRepositoryMock implements PassengerAccountRepository {
  PassengerAccountRepositoryMock() {
    _seed();
  }

  final _rng = Random(1);
  bool _gatewayFailOnce = true;

  final Map<String, _AccountRecord> _accountsById = {};
  final Map<String, String> _accountIdByEmail = {};
  final Map<String, String> _accountIdByPhone = {};
  final Map<String, String> _accountIdByDni = {};

  final Map<String, PassengerPasswordResetSession> _resetByIdentifier = {};

  int _nextId = 1;

  void _seed() {
    _createAccount(
      email: 'pasajero@sdag.pe',
      phone: '999888777',
      dni: '12345678',
      firstName: 'María',
      lastName: 'García',
      birthDate: DateTime(2000, 1, 1),
      password: 'password123',
      role: AppRole.passenger,
      isBlocked: false,
      hasActiveReservation: false,
      name: 'María García',
      preferredPickup: null,
    );

    _createAccount(
      email: 'conductor@sdag.pe',
      phone: '999000111',
      dni: '87654321',
      firstName: 'Conductor',
      lastName: 'Demo',
      birthDate: DateTime(2000, 1, 1),
      password: 'password123',
      role: AppRole.driver,
      isBlocked: false,
      hasActiveReservation: false,
      name: 'Conductor Demo',
      preferredPickup: null,
    );

    _createAccount(
      email: 'admin@sdag.pe',
      phone: '999222333',
      dni: '11223344',
      firstName: 'Admin',
      lastName: 'Demo',
      birthDate: DateTime(2000, 1, 1),
      password: 'password123',
      role: AppRole.admin,
      isBlocked: false,
      hasActiveReservation: false,
      name: 'Admin Demo',
      preferredPickup: null,
    );
  }

  String _createAccount({
    required String? email,
    required String? phone,
    required String? dni,
    required String? firstName,
    required String? lastName,
    required DateTime? birthDate,
    required String password,
    required AppRole role,
    required bool isBlocked,
    required bool hasActiveReservation,
    required String? name,
    required String? preferredPickup,
  }) {
    final id = 'p_${_nextId++}';
    final record = _AccountRecord(
      id: id,
      role: role,
      email: email,
      phone: phone,
      dni: dni,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      password: password,
      isBlocked: isBlocked,
      hasActiveReservation: hasActiveReservation,
      name: name,
      preferredPickup: preferredPickup,
      savedPaymentMethod: null,
    );
    _accountsById[id] = record;
    if (email != null) _accountIdByEmail[email.toLowerCase()] = id;
    if (phone != null) _accountIdByPhone[phone] = id;
    if (dni != null) _accountIdByDni[dni] = id;
    return id;
  }

  Future<void> _delay(int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
  }

  @override
  Future<PassengerAccount> login({
    required String identifier,
    required String password,
  }) async {
    await _delay(450);

    final id = _resolveAccountId(identifier);
    if (id == null) throw const InvalidCredentialsFailure();

    final record = _accountsById[id]!;
    if (record.isBlocked) throw const AccountBlockedFailure();
    if (record.password != password) throw const InvalidCredentialsFailure();

    return record.toAccount();
  }

  @override
  Future<PassengerAccount> registerWithEmail({
    required String email,
    required String dni,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String phone,
    required String password,
  }) async {
    await _delay(550);

    final normalized = email.trim().toLowerCase();
    if (!PassengerAuthValidators.isValidEmail(normalized)) {
      throw const InvalidCredentialsFailure();
    }
    if (_accountIdByEmail.containsKey(normalized)) {
      throw const EmailAlreadyRegisteredFailure();
    }

    final dniDigits = dni.replaceAll(RegExp(r'\D'), '');
    if (dniDigits.length != 8) {
      throw const InvalidCredentialsFailure();
    }
    if (_accountIdByDni.containsKey(dniDigits)) {
      throw const DniAlreadyRegisteredFailure();
    }

    final normalizedPhone = PassengerAuthValidators.normalizePeruPhone(phone);
    if (normalizedPhone == null) {
      throw const InvalidPhoneFailure();
    }
    if (_accountIdByPhone.containsKey(normalizedPhone)) {
      throw const PhoneAlreadyRegisteredFailure();
    }

    final id = _createAccount(
      email: normalized,
      phone: normalizedPhone,
      dni: dniDigits,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      birthDate: birthDate,
      password: password,
      role: AppRole.passenger,
      isBlocked: false,
      hasActiveReservation: false,
      name: '${firstName.trim()} ${lastName.trim()}'.trim(),
      preferredPickup: null,
    );

    return _accountsById[id]!.toAccount();
  }

  @override
  Future<PassengerPasswordResetSession> startPasswordReset({
    required String identifier,
  }) async {
    await _delay(450);

    final id = _resolveAccountId(identifier);
    if (id == null) throw const AccountNotFoundFailure();

    final code = (_rng.nextInt(900000) + 100000).toString();
    final session = PassengerPasswordResetSession(
      identifier: _normalizeIdentifier(identifier),
      code: code,
      createdAt: DateTime.now(),
    );
    _resetByIdentifier[session.identifier] = session;
    return session;
  }

  @override
  Future<void> verifyPasswordResetCode({
    required PassengerPasswordResetSession session,
    required String code,
  }) async {
    await _delay(350);

    final current = _resetByIdentifier[session.identifier];
    if (current == null) throw const ExpiredTokenFailure();
    if (_isExpired(current.createdAt)) throw const ExpiredTokenFailure();
    if (code.trim() != current.code) throw const InvalidVerificationCodeFailure();
  }

  @override
  Future<void> completePasswordReset({
    required PassengerPasswordResetSession session,
    required String newPassword,
  }) async {
    await _delay(500);

    final current = _resetByIdentifier[session.identifier];
    if (current == null) throw const ExpiredTokenFailure();
    if (_isExpired(current.createdAt)) throw const ExpiredTokenFailure();

    final accountId = _resolveAccountId(session.identifier);
    if (accountId == null) throw const AccountNotFoundFailure();

    final record = _accountsById[accountId]!;
    _accountsById[accountId] = record.copyWith(password: newPassword);
    _resetByIdentifier.remove(session.identifier);
  }

  bool _isExpired(DateTime createdAt) {
    final expiresAt = createdAt.add(const Duration(minutes: 30));
    return DateTime.now().isAfter(expiresAt);
  }

  @override
  Future<PassengerAccount> getAccountById(String id) async {
    await _delay(250);
    final record = _accountsById[id];
    if (record == null) throw const AccountNotFoundFailure();
    return record.toAccount();
  }

  @override
  Future<PassengerAccount> updateProfile({
    required String accountId,
    required String name,
    required String email,
    required String phone,
    required String? preferredPickup,
  }) async {
    await _delay(450);

    final record = _accountsById[accountId];
    if (record == null) throw const AccountNotFoundFailure();

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = PassengerAuthValidators.normalizePeruPhone(phone);
    if (normalizedPhone == null) throw const InvalidCredentialsFailure();
    if (!PassengerAuthValidators.isValidEmail(normalizedEmail)) {
      throw const InvalidCredentialsFailure();
    }

    final existingByEmail = _accountIdByEmail[normalizedEmail];
    if (existingByEmail != null && existingByEmail != accountId) {
      throw const DuplicateEmailFailure();
    }

    final existingByPhone = _accountIdByPhone[normalizedPhone];
    if (existingByPhone != null && existingByPhone != accountId) {
      throw const DuplicateEmailFailure();
    }

    if (record.email != null) _accountIdByEmail.remove(record.email!.toLowerCase());
    if (record.phone != null) _accountIdByPhone.remove(record.phone!);

    _accountIdByEmail[normalizedEmail] = accountId;
    _accountIdByPhone[normalizedPhone] = accountId;

    final updated = record.copyWith(
      name: name.trim(),
      email: normalizedEmail,
      phone: normalizedPhone,
      preferredPickup: preferredPickup,
    );
    _accountsById[accountId] = updated;
    return updated.toAccount();
  }

  @override
  Future<PaymentMethod?> getSavedPaymentMethod({required String accountId}) async {
    await _delay(250);
    final record = _accountsById[accountId];
    if (record == null) throw const AccountNotFoundFailure();
    return record.savedPaymentMethod;
  }

  @override
  Future<PaymentMethod> savePaymentMethod({
    required String accountId,
    required PaymentBrand brand,
    required String last4,
    required bool saveForFuture,
  }) async {
    await _delay(550);
    final record = _accountsById[accountId];
    if (record == null) throw const AccountNotFoundFailure();

    if (_gatewayFailOnce) {
      _gatewayFailOnce = false;
      throw const PaymentGatewayFailure();
    }

    if (!_isValidLast4(last4)) throw const PaymentGatewayFailure();

    final token = _tokenize();
    final method = PaymentMethod(
      brand: brand,
      last4: last4,
      token: token,
      saveForFuture: saveForFuture,
    );

    _accountsById[accountId] = record.copyWith(savedPaymentMethod: method);
    return method;
  }

  @override
  Future<PaymentMethod> updatePaymentMethod({
    required String accountId,
    required PaymentMethod method,
  }) async {
    await _delay(450);
    final record = _accountsById[accountId];
    if (record == null) throw const AccountNotFoundFailure();
    _accountsById[accountId] = record.copyWith(savedPaymentMethod: method);
    return method;
  }

  @override
  Future<void> deletePaymentMethod({required String accountId}) async {
    await _delay(350);
    final record = _accountsById[accountId];
    if (record == null) throw const AccountNotFoundFailure();
    _accountsById[accountId] = record.copyWith(savedPaymentMethod: null);
  }

  bool _isValidLast4(String last4) {
    final digits = last4.replaceAll(RegExp(r'\D'), '');
    return digits.length == 4;
  }

  String _tokenize() {
    final part = _rng.nextInt(90000000) + 10000000;
    return 'tok_$part';
  }

  String _normalizeIdentifier(String identifier) {
    final trimmed = identifier.trim();
    if (PassengerAuthValidators.isValidEmail(trimmed)) return trimmed.toLowerCase();
    return trimmed;
  }

  String? _resolveAccountId(String identifier) {
    final normalized = _normalizeIdentifier(identifier);
    if (PassengerAuthValidators.isValidEmail(normalized)) {
      return _accountIdByEmail[normalized];
    }
    return null;
  }
}

class _AccountRecord {
  static const _unset = Object();
  const _AccountRecord({
    required this.id,
    required this.password,
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
  final String password;
  final AppRole role;
  final bool isBlocked;
  final bool hasActiveReservation;
  final String? name;
  final String? email;
  final String? phone;
  final String? dni;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? preferredPickup;
  final PaymentMethod? savedPaymentMethod;

  _AccountRecord copyWith({
    String? password,
    AppRole? role,
    bool? isBlocked,
    bool? hasActiveReservation,
    String? name,
    String? email,
    String? phone,
    String? dni,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    Object? preferredPickup = _unset,
    Object? savedPaymentMethod = _unset,
  }) {
    return _AccountRecord(
      id: id,
      password: password ?? this.password,
      role: role ?? this.role,
      isBlocked: isBlocked ?? this.isBlocked,
      hasActiveReservation: hasActiveReservation ?? this.hasActiveReservation,
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
    );
  }

  PassengerAccount toAccount() {
    return PassengerAccount(
      id: id,
      role: role,
      name: name,
      email: email,
      phone: phone,
      dni: dni,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      preferredPickup: preferredPickup,
      savedPaymentMethod: savedPaymentMethod,
      isBlocked: isBlocked,
      hasActiveReservation: hasActiveReservation,
    );
  }
}
