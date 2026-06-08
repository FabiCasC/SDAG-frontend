import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../router/app_routes.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _identifierController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final email = _identifierController.text.trim().toLowerCase();
    if (email.isEmpty) {
      AppSnackbars.error(context, 'Ingresa tu correo');
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.sdag://reset-password',
      );
      if (!mounted) return;
      AppSnackbars.info(
        context,
        'Te enviamos un enlace a tu correo. Haz clic en él para crear tu nueva contraseña.',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackbars.error(context, 'No se pudo enviar el enlace. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Recuperar contraseña',
      showAppBar: false,
      body: AppAuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBrandHeader(showSlogan: false),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ingresa tu correo',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Te enviaremos un enlace para que puedas crear una nueva contraseña.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              label: 'Correo',
              hint: 'correo@ejemplo.com',
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Enviar',
              loading: _isLoading,
              onPressed: _isLoading ? null : _onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Volver',
              onPressed: _isLoading ? null : () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
