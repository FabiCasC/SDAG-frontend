import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/admin_auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final result = await ref.read(adminAuthProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case AdminLoginResult.ok:
        context.go(AppRoutes.adminHome);
        return;
      case AdminLoginResult.invalidCredentials:
        AppSnackbars.error(context, 'Usuario o contraseña incorrectos');
        return;
      case AdminLoginResult.blocked:
        context.go(AppRoutes.adminBloqueado);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    const top = Color(0xFF0F172A);
    const bottom = Color(0xFF1E293B);
    const badge = Color(0xFFF97316);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.p20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    border: Border.all(color: AppColors.white.withAlpha(46)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.white.withAlpha(46),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: AppColors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'SDAG',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: badge,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'ADMINISTRADOR',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          label: 'Usuario / correo registrado',
                          hint: MockData.adminEmail,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          label: 'Contraseña',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: top,
                            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.r12),
                            ),
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: AppSpacing.lg,
                                  height: AppSpacing.lg,
                                  child: CircularProgressIndicator(
                                    strokeWidth: AppSpacing.progressStrokeWidth,
                                    color: top,
                                  ),
                                )
                              : const Text('Ingresar como administrador'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: _submitting ? null : () => context.push(AppRoutes.adminForgotPassword),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.white,
                          ),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: _submitting ? null : () => context.go(AppRoutes.driverLogin),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.white.withAlpha(230),
                          ),
                          child: const Text('Soy conductor'),
                        ),
                        TextButton(
                          onPressed: _submitting ? null : () => context.go(AppRoutes.login),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.white.withAlpha(230),
                          ),
                          child: const Text('Soy pasajero'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
