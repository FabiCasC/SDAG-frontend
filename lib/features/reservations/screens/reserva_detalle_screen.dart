import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class ReservaDetalleScreen extends ConsumerWidget {
  const ReservaDetalleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reserva = ref.watch(reservaProvider);
    final driver = reserva.conductorSeleccionado;
    final seats = [...reserva.asientosSeleccionados]..sort();
    final active = driver != null && reserva.reservaId != null && seats.isNotEmpty;

    return AppScaffold(
      title: 'Reserva activa',
      body: active
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tienes un viaje en curso',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${driver.name} · ${driver.plate}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Recojo: ${reserva.puntoRecojo ?? '-'}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Asientos: ${seats.map((s) => '#$s').join(', ')}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Ver viaje activo',
                  onPressed: () => context.go(AppRoutes.passengerReservaActiva),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSecondaryButton(
                  label: 'Forzar salida',
                  onPressed: () => context.push(AppRoutes.passengerForzarSalida),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.push(AppRoutes.passengerCancelarReserva),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Cancelar reserva'),
                ),
              ],
            )
          : const PlaceholderPage(
              title: 'No hay una reserva activa',
              subtitle: 'Completa una reserva para ver el detalle y opciones.',
            ),
    );
  }
}
