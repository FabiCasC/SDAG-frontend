import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../router/app_routes.dart';
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
      if (!mounted) return;
      AppSnackbars.success(context, 'Contraseña actualizada');
      context.go(AppRoutes.login);
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
              obscureText: true,
              label: 'Nueva contraseña',
              hint: 'Mínimo 8 caracteres',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirmController,
              obscureText: true,
              label: 'Confirmar contraseña',
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
