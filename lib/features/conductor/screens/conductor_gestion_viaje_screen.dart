import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_auth_provider.dart';
import '../providers/conductor_viaje_provider.dart';

class ConductorGestionViajeScreen extends ConsumerStatefulWidget {
  const ConductorGestionViajeScreen({super.key});

  @override
  ConsumerState<ConductorGestionViajeScreen> createState() =>
      _ConductorGestionViajeScreenState();
}

class _ConductorGestionViajeScreenState
    extends ConsumerState<ConductorGestionViajeScreen> {
  late final ProviderSubscription<ConductorViajeState> _sub;
  int _lastToastId = 0;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<ConductorViajeState>(
      conductorViajeProvider,
      (previous, next) {
        if (!mounted || next.toastMessage == null || next.toastId == _lastToastId) {
          return;
        }

        _lastToastId = next.toastId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          switch (next.toastType ?? ConductorToastType.info) {
            case ConductorToastType.success:
              AppSnackbars.success(context, next.toastMessage!);
            case ConductorToastType.error:
              AppSnackbars.error(context, next.toastMessage!);
            case ConductorToastType.warning:
              AppSnackbars.warning(context, next.toastMessage!);
            case ConductorToastType.info:
              AppSnackbars.info(context, next.toastMessage!);
          }
          ref.read(conductorViajeProvider.notifier).clearToast();
        });
      },
    );
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }

  Future<void> _confirmStartRoute() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar viaje'),
        content: const Text('Se actualizara el estado del viaje a en ruta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(conductorViajeProvider.notifier).iniciarRuta();
    }
  }

  Future<void> _confirmCompleteRoute() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar viaje'),
        content: const Text(
          'Se marcara el viaje como completado y el conductor quedara disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Completar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(conductorViajeProvider.notifier).completarRuta();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(conductorAuthProvider);
    final state = ref.watch(conductorViajeProvider);
    final controller = ref.read(conductorViajeProvider.notifier);

    if (!auth.conductorLogueado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRoutes.driverLogin);
        }
      });
    }

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _ErrorState(
        message: state.errorMessage!,
        onRetry: controller.refresh,
      );
    }

    if (!state.hasActiveTrip) {
      return _EmptyState(onRefresh: controller.refresh);
    }

    final progress = state.totalSeats == 0
        ? 0.0
        : (state.occupiedSeats / state.totalSeats).clamp(0.0, 1.0);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          _TripHeaderCard(state: state),
          const SizedBox(height: AppSpacing.md),
          _OccupancyCard(state: state, progress: progress),
          const SizedBox(height: AppSpacing.md),
          _PassengersCard(passengers: state.pasajerosViaje),
          const SizedBox(height: AppSpacing.lg),
          if (state.estadoViaje == ConductorEstadoViaje.esperando)
            FilledButton(
              onPressed: state.canStartTrip ? _confirmStartRoute : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                backgroundColor: const Color(0xFF16A34A),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF6B7280),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
              ),
              child: Text(
                state.canStartTrip
                    ? 'Iniciar viaje'
                    : 'Iniciar viaje (vehiculo no lleno)',
              ),
            ),
          if (state.estadoViaje == ConductorEstadoViaje.enRuta)
            FilledButton(
              onPressed: state.canCompleteTrip ? _confirmCompleteRoute : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                backgroundColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
              ),
              child: const Text('Completar viaje'),
            ),
          if (state.processingAction) ...[
            const SizedBox(height: AppSpacing.md),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _TripHeaderCard extends StatelessWidget {
  const _TripHeaderCard({required this.state});

  final ConductorViajeState state;

  @override
  Widget build(BuildContext context) {
    final chip = switch (state.estadoViaje) {
      ConductorEstadoViaje.esperando => const _StatusChip(
          label: 'Esperando',
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF166534),
        ),
      ConductorEstadoViaje.enRuta => const _StatusChip(
          label: 'En ruta',
          background: Color(0xFFFFEDD5),
          foreground: Color(0xFF9A3412),
        ),
      ConductorEstadoViaje.completado => const _StatusChip(
          label: 'Completado',
          background: Color(0xFFE5E7EB),
          foreground: Color(0xFF111827),
        ),
    };

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.routeLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              chip,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.directions_bus_rounded,
            label: 'Vehiculo',
            value: [
              if ((state.driverPlate ?? '').isNotEmpty) state.driverPlate!,
              if ((state.vehicleType ?? '').isNotEmpty) state.vehicleType!,
            ].join(' · '),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Salida programada',
            value: _formatDateTime(state.scheduledDepartureAt),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.timer_outlined,
            label: 'ETA',
            value: state.etaMinutes == null ? 'Sin estimacion' : '${state.etaMinutes} min',
          ),
        ],
      ),
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({
    required this.state,
    required this.progress,
  });

  final ConductorViajeState state;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asientos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${state.occupiedSeats} / ${state.totalSeats} ocupados',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.isFull
                ? 'El vehiculo ya completo su capacidad.'
                : 'Faltan ${state.totalSeats - state.occupiedSeats} asientos para llenarse.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _PassengersCard extends StatelessWidget {
  const _PassengersCard({required this.passengers});

  final List<PasajeroViaje> passengers;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pasajeros confirmados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (passengers.isEmpty)
            Text(
              'Esperando reservas...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            )
          else
            ...passengers.map(
              (passenger) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  passenger.nombre,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  passenger.telefono,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Asientos: ${passenger.asientosLabel}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Punto de recojo: ${passenger.puntoRecojo}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (passenger.profileId.isNotEmpty)
                            IconButton(
                              tooltip: 'Chat con pasajero',
                              onPressed: () => context.push('/conductor/chat/${passenger.profileId}'),
                              icon: const Icon(Icons.chat_bubble_outline_rounded),
                              color: const Color(0xFF2563EB),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.route_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No tienes ningun viaje activo en este momento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.shadowBlur,
            offset: Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.p20),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '$label: $value',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Sin horario';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
