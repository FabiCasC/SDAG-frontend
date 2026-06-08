import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart' hide SeatMapWidget;
import '../providers/reserva_provider.dart';

class SeatMapScreen extends ConsumerStatefulWidget {
  const SeatMapScreen({required this.driverId, super.key});

  final String? driverId;

  @override
  ConsumerState<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends ConsumerState<SeatMapScreen> {
  bool _initScheduled = false;

  MockDriver? _findDriver(String? id) {
    if (id == null) return null;
    for (final d in MockData.drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservaProvider);
    final controller = ref.read(reservaProvider.notifier);
    final driverFromQuery = _findDriver(widget.driverId);
    final driver = state.conductorSeleccionado ?? driverFromQuery;
    final occupiedAsync = ref.watch(occupiedSeatsByPlateProvider(driver?.plate ?? ''));

    if (driver == null) {
      return const AppScaffold(
        title: 'Seleccionar asientos',
        body: PlaceholderPage(
          title: 'Conductor no seleccionado',
          subtitle: 'Vuelve a la búsqueda y selecciona un conductor.',
        ),
      );
    }

    if (!_initScheduled &&
        driverFromQuery != null &&
        state.conductorSeleccionado?.id != driverFromQuery.id) {
      _initScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.startWithDriver(driverFromQuery);
      });
    }

    final selectedSeats = state.asientosSeleccionados.toSet();
    final occupiedSeats = occupiedAsync.valueOrNull?.toSet() ?? <int>{};

    final canContinue = selectedSeats.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Seleccionar asientos'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.p20,
                AppSpacing.p20,
                AppSpacing.p20,
                140,
              ),
              children: [
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${driver.vehicleType} · ${driver.totalSeats} asientos · ${driver.plate}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Elige tus asientos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                SeatMapWidget(
                  capacidad: driver.totalSeats,
                  asientosOcupados: occupiedSeats.toList()..sort(),
                  asientosSeleccionados: state.asientosSeleccionados,
                  onSeatTapped: (seatNumber) {
                    if (occupiedSeats.contains(seatNumber)) return;

                    final next = selectedSeats.toSet();
                    if (next.contains(seatNumber)) {
                      next.remove(seatNumber);
                      controller.setSelectedSeats(next.toList());
                      return;
                    }

                    if (next.length >= 4) {
                      AppSnackbars.warning(context, 'Máximo 4 asientos');
                      return;
                    }

                    next.add(seatNumber);
                    controller.setSelectedSeats(next.toList());
                  },
                ),
              ],
            ),
            _BottomPanel(
              selectedCount: state.asientosSeleccionados.length,
              total: state.montoTotal,
              enabled: canContinue,
              onContinue: canContinue
                  ? () {
                      if (state.asientosSeleccionados.length == 1) {
                        context.push(AppRoutes.passengerReservaPickup);
                      } else {
                        context.push(AppRoutes.passengerReservaAcompanantes);
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class SeatMapWidget extends StatelessWidget {
  const SeatMapWidget({
    required this.capacidad,
    required this.asientosOcupados,
    required this.asientosSeleccionados,
    required this.onSeatTapped,
    super.key,
  });

  final int capacidad;
  final List<int> asientosOcupados;
  final List<int> asientosSeleccionados;
  final ValueChanged<int> onSeatTapped;

  @override
  Widget build(BuildContext context) {
    final occupied = asientosOcupados.toSet();
    final selected = asientosSeleccionados.toSet();

    Widget buildSeat(int seatNumber) {
      final state = occupied.contains(seatNumber)
          ? _SeatVisualState.occupied
          : selected.contains(seatNumber)
              ? _SeatVisualState.selected
              : _SeatVisualState.available;

      final enabled = state != _SeatVisualState.occupied;

      return _SeatTile(
        seatNumber: seatNumber,
        state: state,
        enabled: enabled,
        onTap: () => onSeatTapped(seatNumber),
      );
    }

    final remaining = (capacidad - 2).clamp(0, capacidad);
    final rows = remaining == 0 ? 0 : (remaining / 2).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: buildSeat(1)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: capacidad >= 2 ? buildSeat(2) : const SizedBox.shrink()),
          ],
        ),
        if (rows > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1,
            ),
            itemCount: rows * 2,
            itemBuilder: (context, index) {
              final seatNumber = index + 3;
              if (seatNumber > capacidad) return const SizedBox.shrink();
              return buildSeat(seatNumber);
            },
          ),
        ],
      ],
    );
  }
}

enum _SeatVisualState { available, occupied, selected }

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.seatNumber,
    required this.state,
    required this.enabled,
    required this.onTap,
  });

  final int seatNumber;
  final _SeatVisualState state;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (bg, border, fg) = switch (state) {
      _SeatVisualState.available => (AppColors.seatOkBg, AppColors.success, AppColors.success),
      _SeatVisualState.occupied => (AppColors.fieldFill, AppColors.border, AppColors.textSecondary),
      _SeatVisualState.selected => (AppColors.infoSurface, AppColors.primaryBlue, AppColors.primaryBlue),
    };

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.r8),
      child: Ink(
        width: AppSpacing.seatSize,
        height: AppSpacing.seatSize,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.r8),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(
            '$seatNumber',
            style: theme.textTheme.titleMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.selectedCount,
    required this.total,
    required this.enabled,
    required this.onContinue,
  });

  final int selectedCount;
  final double total;
  final bool enabled;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppSpacing.bottomNavShadowBlur,
              offset: const Offset(0, AppSpacing.bottomNavShadowOffsetY),
            ),
          ],
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Asientos seleccionados: $selectedCount',
                    style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                Text(
                  'Total: S/ ${total.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Continuar',
              onPressed: enabled ? onContinue : null,
            ),
          ],
        ),
      ),
    );
  }
}
