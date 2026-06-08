import 'package:flutter/foundation.dart';

import '../../data/models/app_role.dart';

class AppSession extends ChangeNotifier {
  bool _isLoggedIn = false;
  AppRole? _role;
  String? _email;

  bool get isLoggedIn => _isLoggedIn;
  AppRole? get role => _role;
  String? get email => _email;

  Future<void> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _isLoggedIn = true;
    _email = email.trim().isEmpty ? 'demo@sdag.pe' : email.trim();
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _isLoggedIn = true;
    _email = email.trim().isEmpty ? 'demo@sdag.pe' : email.trim();
    notifyListeners();
  }

  Future<void> requestPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  void setRole(AppRole role) {
    _role = role;
    notifyListeners();
  }

  void clearRole() {
    _role = null;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _role = null;
    _email = null;
    notifyListeners();
  }
}

