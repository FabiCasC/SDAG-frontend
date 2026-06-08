import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_auth_provider.dart';

class ConductorBloqueadoScreen extends ConsumerWidget {
  const ConductorBloqueadoScreen({super.key});

  Future<void> _confirmar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar recepción'),
          content: const Text('¿Confirmas que recibiste el pago de tu comisión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await ref.read(conductorAuthProvider.notifier).confirmarPago();
    if (!context.mounted) return;
    AppSnackbars.success(context, '¡Acceso desbloqueado! Bienvenido.');
    context.go(AppRoutes.driverHome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(conductorAuthProvider);
    if (auth.pagoConfirmado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRoutes.driverHome);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF2F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go(AppRoutes.driverLogin),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const Icon(
                Icons.lock_rounded,
                size: 84,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Acceso bloqueado',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No confirmaste la recepción del pago de tu comisión del día anterior. Debes confirmarla para poder operar hoy.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  border: Border.all(color: AppColors.primaryBlue),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Para desbloquear:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _StepRow(index: 1, text: 'Verifica que recibiste el pago'),
                      const SizedBox(height: AppSpacing.xs),
                      const _StepRow(index: 2, text: "Presiona 'Confirmar recepción'"),
                      const SizedBox(height: AppSpacing.xs),
                      const _StepRow(index: 3, text: 'Tu acceso se desbloqueará inmediatamente'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              AppCriticalButton(
                label: 'Confirmar recepción de pago',
                onPressed: () => _confirmar(context, ref),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                ),
                onPressed: () {
                  AppSnackbars.info(context, 'Se notificó al administrador');
                },
                child: const Text('Contactar administrador'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$index',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

