import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

class ReservaActivaScreen extends ConsumerWidget {
  const ReservaActivaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reserva = ref.watch(reservaProvider);
    final driver = reserva.conductorSeleccionado;
    final seats = [...reserva.asientosSeleccionados]..sort();

    if (driver == null || reserva.reservaId == null || seats.isEmpty) {
      return const AppScaffold(
        title: 'Mi reserva',
        body: PlaceholderPage(
          title: 'No tienes una reserva activa',
          subtitle: 'Realiza una búsqueda y confirma una reserva.',
        ),
      );
    }

    return AppScaffold(
      title: 'Mi reserva',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reserva ${reserva.reservaId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${driver.name} · ${driver.plate}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Asientos: ${seats.map((s) => '#$s').join(', ')}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Forzar salida anticipada',
            onPressed: () => context.push(AppRoutes.passengerForzarSalida),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            ),
            onPressed: () => context.push(AppRoutes.passengerCancelarReserva),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
  }
}

