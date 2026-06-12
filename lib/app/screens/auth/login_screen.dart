import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/app_routes.dart';
import '../../providers/passenger/controllers/passenger_login_controller.dart';
import '../../../core/mock/mock_data.dart';
import '../../../features/admin/providers/admin_auth_provider.dart';
import '../../../features/conductor/providers/conductor_auth_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;

  bool _passwordVisible = false;
  bool _rememberMe = false;
  bool _passwordUpdatedSnackShown = false;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadSavedCredentials());
      _maybeShowPasswordUpdatedSnack();
    });
  }

  void _maybeShowPasswordUpdatedSnack() {
    if (_passwordUpdatedSnackShown || !mounted) return;
    final updated = GoRouterState.of(context).uri.queryParameters['passwordUpdated'] == '1';
    if (!updated) return;
    _passwordUpdatedSnackShown = true;
    AppSnackbars.success(context, 'Contraseña actualizada correctamente');
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (!rememberMe || savedEmail == null || savedPassword == null) return;
    if (!mounted) return;

    setState(() {
      _rememberMe = true;
      _identifierController.text = savedEmail;
      _passwordController.text = savedPassword;
    });
    final loginNotifier = ref.read(passengerLoginControllerProvider.notifier);
    loginNotifier.setIdentifier(savedEmail);
    loginNotifier.setPassword(savedPassword);
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPassenger(String email, String password) async {
    final controller = ref.read(passengerLoginControllerProvider.notifier);
    final error = await controller.submit();
    if (!mounted) return;
    if (error != null) {
      AppSnackbars.error(context, error);
      return;
    }
    if (!mounted) return;
    await _saveCredentials(email, password);
    if (!mounted) return;
    context.go(AppRoutes.passengerHome);
  }

  Future<void> _onLogin() async {
    final email = _identifierController.text.trim();
    final password = _passwordController.text;
    final normalized = email.toLowerCase();

    final prefs = await SharedPreferences.getInstance();
    final adminEmail = (prefs.getString('sdag_admin_profile_email') ?? MockData.adminEmail)
        .trim()
        .toLowerCase();

    if (normalized == adminEmail) {
      final result = await ref.read(adminAuthProvider.notifier).login(
            email: email,
            password: password,
          );
      if (!mounted) return;
      switch (result) {
        case AdminLoginResult.ok:
          await _saveCredentials(email, password);
          if (!mounted) return;
          context.go(AppRoutes.adminHome);
          return;
        case AdminLoginResult.blocked:
          await _saveCredentials(email, password);
          if (!mounted) return;
          context.go(AppRoutes.adminBloqueado);
          return;
        case AdminLoginResult.invalidCredentials:
          AppSnackbars.error(context, 'Usuario o contraseña incorrectos');
          return;
      }
    }

    if (normalized == MockData.conductorEmail.toLowerCase()) {
      final result = await ref.read(conductorAuthProvider.notifier).login(
            email: email,
            password: password,
          );
      if (!mounted) return;
      switch (result) {
        case ConductorLoginResult.ok:
          await _saveCredentials(email, password);
          if (!mounted) return;
          context.go(AppRoutes.driverHome);
          return;
        case ConductorLoginResult.inactiveAccount:
          AppSnackbars.warning(context, 'Tu cuenta está desactivada. Contacta al administrador');
          return;
        case ConductorLoginResult.invalidCredentials:
          AppSnackbars.error(context, 'Credenciales inválidas');
          return;
      }
    }

    final passengerController = ref.read(passengerLoginControllerProvider.notifier);
    passengerController.setIdentifier(email);
    passengerController.setPassword(password);
    await _onLoginPassenger(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerLoginControllerProvider);
    final passengerController = ref.read(passengerLoginControllerProvider.notifier);

    return AppScaffold(
      title: 'RutasChosica',
      showAppBar: false,
      body: AppAuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBrandHeader(),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              label: 'Correo',
              hint: 'correo@ejemplo.com',
              onChanged: passengerController.setIdentifier,
            ),
            if (state.identifierError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.identifierError!),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              label: 'Contraseña',
              onChanged: passengerController.setPassword,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (state.passwordError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.passwordError!),
            ],
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: _rememberMe,
              onChanged: state.isSubmitting
                  ? null
                  : (value) => setState(() => _rememberMe = value ?? false),
              title: const Text('Recordar mis datos'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Iniciar sesión',
              loading: state.isSubmitting,
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      await _onLogin();
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              onPressed: state.isSubmitting ? null : () => context.push(AppRoutes.register),
              label: 'Crear cuenta',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => context.push(AppRoutes.forgotPassword),
              child: const Text('Olvidé mi contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
