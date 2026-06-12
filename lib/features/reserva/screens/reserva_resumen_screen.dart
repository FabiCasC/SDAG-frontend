import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_navigation_back.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';
import 'seat_map_screen.dart';

class ReservaResumenScreen extends ConsumerWidget {
  const ReservaResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservaProvider);
    final driver = state.conductorSeleccionado;
    final occupiedAsync = ref.watch(occupiedSeatsByTripProvider(driver?.tripId ?? ''));

    if (driver == null) {
      return const AppScaffold(
        title: 'Resumen de reserva',
        body: PlaceholderPage(
          title: 'Reserva incompleta',
          subtitle: 'Vuelve a seleccionar conductor y asientos.',
        ),
      );
    }

    final seats = [...state.asientosSeleccionados]..sort();
    final companions = state.acompanantes;
    final occupiedSeats = occupiedAsync.valueOrNull ?? const <int>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: AppBarLeadingBack(fallbackRoute: AppRoutes.passengerReservaPickup),
        title: const Text('Resumen de reserva'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            AbsorbPointer(
              child: SeatMapWidget(
  seatCount: driver.totalSeats,
  occupiedSeats: Set<int>.from(occupiedSeats),
  selectedSeats: Set<int>.from(seats),
  onSeatTap: (_) {},
),
            ),
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.r16),
                border: Border.all(color: AppColors.primaryBlue),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: AppSpacing.shadowBlur,
                    offset: Offset(0, AppSpacing.shadowOffsetY),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DriverHeader(
                      name: driver.name,
                      plate: driver.plate,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _LineItem(label: 'Ruta', value: driver.routeLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _LineItem(
                      label: 'Recojo',
                      value: (state.puntoRecojo?.trim().isNotEmpty ?? false)
                          ? state.puntoRecojo!.trim()
                          : '-',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Asientos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...seats.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          '• Asiento $s',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                    if (seats.length > 1) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Acompañantes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...seats.sublist(1).map((seat) {
                        final a = companions[seat];
                        final text = a == null
                            ? '• Asiento $seat: -'
                            : '• Asiento $seat: ${a.fullName} · DNI ${a.dni}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            text,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'S/ ${state.montoTotal.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Editar',
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.energeticOrange,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => context.push(AppRoutes.passengerPago),
                    child: const Text('Confirmar y pagar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverHeader extends StatelessWidget {
  const _DriverHeader({required this.name, required this.plate});

  final String name;
  final String plate;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryTint12,
          child: Text(
            initials,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            plate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
