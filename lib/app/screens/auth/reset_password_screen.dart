import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final pw = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pw.length < 8) {
      AppSnackbars.error(context, 'La contraseña debe tener al menos 8 caracteres');
      return;
    }
    if (pw != confirm) {
      AppSnackbars.error(context, 'Las contraseñas no coinciden');
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pw),
      );
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      context.go('${AppRoutes.login}?passwordUpdated=1');
    } on AuthException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackbars.error(context, 'No se pudo actualizar la contraseña');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nueva contraseña',
      showAppBar: false,
      body: AppAuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBrandHeader(showSlogan: false),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Crea tu nueva contraseña',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              label: 'Nueva contraseña',
              hint: 'Mínimo 8 caracteres',
              suffixIcon: IconButton(
                onPressed: _isLoading ? null : () => setState(() => _passwordVisible = !_passwordVisible),
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirmController,
              obscureText: !_confirmPasswordVisible,
              label: 'Confirmar contraseña',
              suffixIcon: IconButton(
                onPressed:
                    _isLoading ? null : () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                icon: Icon(
                  _confirmPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Guardar contraseña',
              loading: _isLoading,
              onPressed: _isLoading ? null : _onSave,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Volver a login',
              onPressed: _isLoading ? null : () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
