import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class ConductorForgotPasswordScreen extends StatefulWidget {
  const ConductorForgotPasswordScreen({super.key});

  @override
  State<ConductorForgotPasswordScreen> createState() => _ConductorForgotPasswordScreenState();
}

class _ConductorForgotPasswordScreenState extends State<ConductorForgotPasswordScreen> {
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
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _sending = false);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enlace enviado'),
          content: const Text(
            'Enlace enviado al correo registrado por tu administrador. Expira en 30 min.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Recuperar acceso',
      actions: [
        IconButton(
          onPressed: () => context.go(AppRoutes.driverLogin),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ingresa el correo registrado por el administrador.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            label: 'Correo',
            hint: 'conductor@sdag.pe',
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Enviar enlace',
            loading: _sending,
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }
}
