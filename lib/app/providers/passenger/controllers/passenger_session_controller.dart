import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';

import '../models/passenger_account.dart';
import '../repositories/passenger_account_repository.dart';
import '../repositories/passenger_account_repository_supabase.dart';

class PassengerSessionState {
  const PassengerSessionState({
    required this.isLoading,
    required this.account,
  });

  final bool isLoading;
  final PassengerAccount? account;

  bool get isAuthenticated => account != null;

  PassengerSessionState copyWith({
    bool? isLoading,
    PassengerAccount? account,
  }) {
    return PassengerSessionState(
      isLoading: isLoading ?? this.isLoading,
      account: account,
    );
  }

  static PassengerSessionState initial() =>
      const PassengerSessionState(isLoading: false, account: null);
}

final passengerAccountRepositoryProvider =
    Provider<PassengerAccountRepository>((ref) {
  return PassengerAccountRepositorySupabase(client: Supabase.instance.client);
});

final passengerSessionProvider =
    StateNotifierProvider<PassengerSessionController, PassengerSessionState>(
  (ref) => PassengerSessionController(
    repository: ref.read(passengerAccountRepositoryProvider),
  ),
);

class PassengerSessionController extends StateNotifier<PassengerSessionState> {
  PassengerSessionController({required this.repository})
      : super(PassengerSessionState.initial()) {
    _bootstrap();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _bootstrap();
    });
  }

  final PassengerAccountRepository repository;
  StreamSubscription<AuthState>? _authSub;
  bool _bootstrapping = false;

  Future<void> _bootstrap() async {
    if (_bootstrapping) return;
    _bootstrapping = true;
    state = state.copyWith(isLoading: true);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        state = PassengerSessionState.initial();
        return;
      }

      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();
      final role = row?['role']?.toString();
      if (role != 'passenger') {
        if (!mounted) return;
        state = PassengerSessionState.initial();
        return;
      }

      final account = await repository.getAccountById(session.user.id);
      if (!mounted) return;
      state = PassengerSessionState(isLoading: false, account: account);
    } catch (_) {
      if (!mounted) return;
      state = PassengerSessionState(isLoading: false, account: null);
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    final account = await repository.login(identifier: identifier, password: password);
    state = PassengerSessionState(isLoading: false, account: account);
  }

  Future<void> registerWithEmail({
    required String email,
    required String dni,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    final account = await repository.registerWithEmail(
      email: email,
      dni: dni,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      phone: phone,
      password: password,
    );
    state = PassengerSessionState(isLoading: false, account: account);
  }

  Future<void> refreshAccount() async {
    final current = state.account;
    if (current == null) return;
    final account = await repository.getAccountById(current.id);
    state = PassengerSessionState(isLoading: false, account: account);
  }

  void logout() {
    state = PassengerSessionState.initial();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
