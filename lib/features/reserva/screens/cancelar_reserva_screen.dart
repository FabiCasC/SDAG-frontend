import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

class CancelarReservaScreen extends ConsumerWidget {
  const CancelarReservaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reserva = ref.watch(reservaProvider);

    final vehiculoPartio = reserva.vehiculoPartio;
    final monto = reserva.montoTotal;

    return AppScaffold(
      title: 'Cancelar reserva',
      body: vehiculoPartio
          ? _VehicleDepartedCard(
              onClose: () => context.pop(),
            )
          : _CancelableCard(
              monto: monto,
              onConfirm: () {
                context.push('${AppRoutes.passengerReembolso}?amount=${monto.toStringAsFixed(0)}');
              },
            ),
    );
  }
}

class _CancelableCard extends StatelessWidget {
  const _CancelableCard({required this.monto, required this.onConfirm});

  final double monto;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.seatWarnBg,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Puedes cancelar antes de que el vehículo parta. Se iniciará el reembolso según condiciones.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Monto a reembolsar:',
                    style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  'S/ ${monto.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          ),
          onPressed: onConfirm,
          child: const Text('Confirmar cancelación'),
        ),
      ],
    );
  }
}

class _VehicleDepartedCard extends StatelessWidget {
  const _VehicleDepartedCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.seatBadBg,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.error),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'El vehículo ya partió',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'No es posible cancelar ni obtener reembolso una vez iniciado el viaje.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        AppSecondaryButton(
          label: 'Entendido',
          onPressed: onClose,
        ),
      ],
    );
  }
}
