import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() => _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _sending = false);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listo'),
        content: const Text(
          'Enlace de recuperación enviado. Expira en 30 minutos.\n'
          'Revisa el correo registrado en el sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Recuperar acceso',
      actions: [
        IconButton(
          onPressed: () => context.go(AppRoutes.adminLogin),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ingresa el correo registrado.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            label: 'Correo registrado',
            hint: 'admin@sdag.pe',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Si no recuerdas el correo registrado, contacta al soporte técnico.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Enviar enlace de recuperación',
            loading: _sending,
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }
}

