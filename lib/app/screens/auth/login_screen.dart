import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/app_routes.dart';
import '../../providers/passenger/controllers/passenger_login_controller.dart';
import '../../providers/passenger/controllers/passenger_session_controller.dart';
import '../../../core/mock/mock_data.dart';
import '../../../features/admin/providers/admin_auth_provider.dart';
import '../../../features/conductor/providers/conductor_auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPassenger() async {
    final controller = ref.read(passengerLoginControllerProvider.notifier);
    final error = await controller.submit();
    if (!mounted) return;
    if (error != null) {
      AppSnackbars.error(context, error);
      return;
    }
    await ref.read(adminAuthProvider.notifier).logout();
    await ref.read(conductorAuthProvider.notifier).logout();
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
          ref.read(passengerSessionProvider.notifier).logout();
          await ref.read(conductorAuthProvider.notifier).logout();
          if (!mounted) return;
          context.go(AppRoutes.adminHome);
          return;
        case AdminLoginResult.blocked:
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
          ref.read(passengerSessionProvider.notifier).logout();
          await ref.read(adminAuthProvider.notifier).logout();
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
    await _onLoginPassenger();
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
              obscureText: true,
              label: 'Contraseña',
              onChanged: passengerController.setPassword,
            ),
            if (state.passwordError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.passwordError!),
            ],
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
