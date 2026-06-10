import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/models/app_role.dart';
import '../models/passenger_account.dart';
import '../models/payment_method.dart';
import 'passenger_account_repository.dart';

class PassengerAccountRepositorySupabase implements PassengerAccountRepository {
  PassengerAccountRepositorySupabase({required this.client});

  final SupabaseClient client;

  @override
  Future<PassengerAccount> login({
    required String identifier,
    required String password,
  }) async {
    final email = identifier.trim().toLowerCase();
    final pw = password.trim();
    try {
      final res = await client.auth.signInWithPassword(email: email, password: pw);
      final user = res.user ?? client.auth.currentUser;
      if (user == null) throw const InvalidCredentialsFailure();

      final profile = await _ensureProfile(userId: user.id, email: email);
      return _mapProfile(profile);
    } on AuthException {
      throw const InvalidCredentialsFailure();
    } on PostgrestException catch (e) {
      throw GenericPassengerAuthFailure(_dbMessage(e));
    }
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
    final normalizedEmail = email.trim().toLowerCase();
    final pw = password.trim();
    final normalizedDni = dni.trim();
    final normalizedPhone = phone.trim();
    try {
      final res = await client.auth.signUp(email: normalizedEmail, password: pw);
      final user = res.user ?? client.auth.currentUser;
      if (user == null) {
        throw const GenericPassengerAuthFailure('No se pudo completar el registro');
      }

      // Espera un momento para que la sesión se establezca
      await Future.delayed(const Duration(milliseconds: 500));

      // Intenta actualizar el profile que el trigger ya creó
      try {
        await client.from('profiles').update({
          'role': AppRole.passenger.name,
          'dni': normalizedDni,
          'phone': normalizedPhone,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'birth_date': birthDate.toIso8601String().substring(0, 10),
          'name': '${firstName.trim()} ${lastName.trim()}'.trim(),
          'is_blocked': false,
          'has_active_reservation': false,
        }).eq('id', user.id);
      } catch (_) {
        // Si falla el update, no bloqueamos el registro
      }

      // Refresca la sesión para asegurar que está activa
      await client.auth.refreshSession();
      await Future.delayed(const Duration(milliseconds: 300));

      // Lee el profile final
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return _mapProfile(profile);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already') || msg.contains('registered') || msg.contains('exists')) {
        throw const EmailAlreadyRegisteredFailure();
      }
      throw GenericPassengerAuthFailure(e.message);
    } on PostgrestException catch (e) {
      final mapped = _mapUniqueViolation(e);
      if (mapped != null) throw mapped;
      throw GenericPassengerAuthFailure(_dbMessage(e));
    }
  }

  @override
  Future<PassengerPasswordResetSession> startPasswordReset({
    required String identifier,
  }) async {
    final email = identifier.trim().toLowerCase();
    try {
      await client.auth.resetPasswordForEmail(email);
      return PassengerPasswordResetSession(
        identifier: email,
        code: 'EMAIL',
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw GenericPassengerAuthFailure(e.message);
    }
  }

  @override
  Future<void> verifyPasswordResetCode({
    required PassengerPasswordResetSession session,
    required String code,
  }) async {
    if (code.trim().isEmpty) throw const InvalidVerificationCodeFailure();
    return;
  }

  @override
  Future<void> completePasswordReset({
    required PassengerPasswordResetSession session,
    required String newPassword,
  }) async {
    final pw = newPassword.trim();
    try {
      await client.auth.updateUser(UserAttributes(password: pw));
    } on AuthException catch (e) {
      throw GenericPassengerAuthFailure(e.message);
    }
  }

  @override
  Future<PassengerAccount> getAccountById(String id) async {
    try {
      final profile = await client.from('profiles').select().eq('id', id).single();
      return _mapProfile(profile);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const AccountNotFoundFailure();
      throw GenericPassengerAuthFailure(_dbMessage(e));
    }
  }

  @override
  Future<PassengerAccount> updateProfile({
    required String accountId,
    required String name,
    required String email,
    required String phone,
    required String? preferredPickup,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'preferred_pickup': preferredPickup?.trim(),
      };
      final profile = await client.from('profiles').update(payload).eq('id', accountId).select().single();
      return _mapProfile(profile);
    } on PostgrestException catch (e) {
      final mapped = _mapUniqueViolation(e);
      if (mapped != null) throw mapped;
      throw GenericPassengerAuthFailure(_dbMessage(e));
    }
  }

  @override
  Future<PaymentMethod?> getSavedPaymentMethod({required String accountId}) async {
    try {
      final row = await client.from('payment_methods').select().eq('profile_id', accountId).maybeSingle();
      if (row == null) return null;
      return _mapPaymentMethod(row);
    } on PostgrestException catch (e) {
      throw GenericPassengerAuthFailure(_dbMessage(e));
    }
  }

  @override
  Future<PaymentMethod> savePaymentMethod({
    required String accountId,
    required PaymentBrand brand,
    required String last4,
    required bool saveForFuture,
  }) async {
    try {
      final payload = <String, dynamic>{
        'profile_id': accountId,
        'brand': brand.name,
        'last4': last4.trim(),
        'token': 'tok_${DateTime.now().microsecondsSinceEpoch}',
        'save_for_future': saveForFuture,
      };
      final row = await client.from('payment_methods').upsert(payload).select().single();
      return _mapPaymentMethod(row);
    } on PostgrestException catch (e) {
      throw GenericPassengerAuthFailure(_dbMessage(e));
    }
  }

  @override
  Future<PaymentMethod> updatePaymentMethod({
    required String accountId,
    required PaymentMethod method,
  }) async {
    try {
      final payload = <String, dynamic>{
        'brand': method.brand.name,
        'last4': method.last4,
        'token': method.token,
        'save_for_future': method.saveForFuture,
      };
      final row = await client.from('payment_methods').update(payload).eq('profile_id', accountId).select().single();
      return _mapPaymentMethod(row);
    } on PostgrestException catch (e) {
      throw GenericPassengerAuthFailure(_dbMessage(e));
    }
  }

  @override
  Future<void> deletePaymentMethod({required String accountId}) async {
    try {
      await client.from('payment_methods').delete().eq('profile_id', accountId);
    } on PostgrestException catch (e) {
      throw GenericPassengerAuthFailure(_dbMessage(e));
    }
  }

  Future<Map<String, dynamic>> _ensureProfile({
    required String userId,
    required String email,
  }) async {
    Map<String, dynamic>? existing;
    try {
      existing = await client.from('profiles').select().eq('id', userId).maybeSingle();
    } on PostgrestException catch (e) {
      _logPostgrestException('profiles.select (ensure)', e, userId: userId);
      throw const GenericPassengerAuthFailure(
        'No se pudo leer tu perfil. Revisa las policies (RLS) de profiles.',
      );
    }

    if (existing != null) return existing;

    try {
      final created = await client.from('profiles').insert({
        'id': userId,
        'role': AppRole.passenger.name,
        'email': email,
        'is_blocked': false,
        'has_active_reservation': false,
      }).select().single();
      return created;
    } on PostgrestException catch (e) {
      _logPostgrestException('profiles.insert (ensure)', e, userId: userId);
      throw const GenericPassengerAuthFailure(
        'No se pudo crear tu perfil. Revisa las policies (RLS) de profiles.',
      );
    }
  }

  void _logPostgrestException(
    String operation,
    PostgrestException e, {
    String? userId,
  }) {
    debugPrint(
      '[Supabase][$operation] userId=$userId code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}',
    );
  }

  PassengerAccount _mapProfile(Map<String, dynamic> row) {
    final roleRaw = row['role']?.toString() ?? AppRole.passenger.name;
    final role = AppRole.values
        .where((e) => e.name == roleRaw)
        .cast<AppRole?>()
        .firstWhere((e) => e != null, orElse: () => AppRole.passenger)!;

    DateTime? birthDate;
    final bd = row['birth_date'];
    if (bd is String) birthDate = DateTime.tryParse(bd);

    return PassengerAccount(
      id: row['id'].toString(),
      role: role,
      name: row['name'] as String?,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      dni: row['dni'] as String?,
      firstName: row['first_name'] as String?,
      lastName: row['last_name'] as String?,
      birthDate: birthDate,
      preferredPickup: row['preferred_pickup'] as String?,
      savedPaymentMethod: null,
      isBlocked: (row['is_blocked'] as bool?) ?? false,
      hasActiveReservation: (row['has_active_reservation'] as bool?) ?? false,
    );
  }

  PaymentMethod _mapPaymentMethod(Map<String, dynamic> row) {
    final brandRaw = row['brand']?.toString() ?? PaymentBrand.visa.name;
    final brand = PaymentBrand.values
        .where((e) => e.name == brandRaw)
        .cast<PaymentBrand?>()
        .firstWhere((e) => e != null, orElse: () => PaymentBrand.visa)!;
    return PaymentMethod(
      brand: brand,
      last4: row['last4']?.toString() ?? '0000',
      token: row['token']?.toString() ?? '',
      saveForFuture: (row['save_for_future'] as bool?) ?? true,
    );
  }

  PassengerAuthFailure? _mapUniqueViolation(PostgrestException e) {
    final lower = e.message.toLowerCase();
    if (lower.contains('email')) return const EmailAlreadyRegisteredFailure();
    if (lower.contains('phone')) return const PhoneAlreadyRegisteredFailure();
    if (lower.contains('dni')) return const DniAlreadyRegisteredFailure();
    if (e.code == '23505') return const DuplicateEmailFailure();
    return null;
  }

  String _dbMessage(PostgrestException e) {
    final msg = e.message.trim();
    return msg.isEmpty ? 'Error de base de datos' : msg;
  }
}
