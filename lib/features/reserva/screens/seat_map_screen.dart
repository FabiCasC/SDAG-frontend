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

    Widget buildPassengerSeat(int seatNumber) {
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

    Widget buildDriverSeat() => const _DriverSeatTile();

    Widget row2({
      required Widget left,
      required Widget right,
    }) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: right),
        ],
      );
    }

    Widget row3({
      required Widget left,
      required Widget middle,
      required Widget right,
    }) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: middle),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: right),
        ],
      );
    }

    Widget rowAisle({
      required Widget left,
      required Widget right,
    }) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: right),
        ],
      );
    }

    List<Widget> layoutRows() {
      switch (capacidad) {
        case 4:
          return [
            row2(left: buildDriverSeat(), right: buildPassengerSeat(1)),
            const SizedBox(height: AppSpacing.sm),
            row3(
              left: buildPassengerSeat(2),
              middle: buildPassengerSeat(3),
              right: buildPassengerSeat(4),
            ),
          ];
        case 6:
          return [
            row2(left: buildDriverSeat(), right: buildPassengerSeat(1)),
            const SizedBox(height: AppSpacing.sm),
            row2(left: buildPassengerSeat(2), right: buildPassengerSeat(3)),
            const SizedBox(height: AppSpacing.sm),
            row3(
              left: buildPassengerSeat(4),
              middle: buildPassengerSeat(5),
              right: buildPassengerSeat(6),
            ),
          ];
        case 8:
          return [
            row2(left: buildDriverSeat(), right: buildPassengerSeat(1)),
            const SizedBox(height: AppSpacing.sm),
            row2(left: buildPassengerSeat(2), right: buildPassengerSeat(3)),
            const SizedBox(height: AppSpacing.sm),
            row2(left: buildPassengerSeat(4), right: buildPassengerSeat(5)),
            const SizedBox(height: AppSpacing.sm),
            row3(
              left: buildPassengerSeat(6),
              middle: buildPassengerSeat(7),
              right: buildPassengerSeat(8),
            ),
          ];
        case 15:
          final rows = <Widget>[
            row2(left: buildDriverSeat(), right: buildPassengerSeat(1)),
          ];
          for (var seat = 2; seat <= 15; seat += 2) {
            rows.add(const SizedBox(height: AppSpacing.sm));
            rows.add(
              rowAisle(
                left: buildPassengerSeat(seat),
                right: buildPassengerSeat(seat + 1),
              ),
            );
          }
          return rows;
        default:
          final perRow = 2;
          final totalRows = (capacidad / perRow).ceil();
          final widgets = <Widget>[];
          for (var r = 0; r < totalRows; r++) {
            if (r > 0) widgets.add(const SizedBox(height: AppSpacing.sm));
            final leftSeat = r * perRow + 1;
            final rightSeat = r * perRow + 2;
            widgets.add(
              row2(
                left: buildPassengerSeat(leftSeat),
                right: rightSeat <= capacidad
                    ? buildPassengerSeat(rightSeat)
                    : const SizedBox.shrink(),
              ),
            );
          }
          return widgets;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: layoutRows(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SeatLegend(),
      ],
    );
  }
}

enum _SeatVisualState { available, occupied, selected }

class _DriverSeatTile extends StatelessWidget {
  const _DriverSeatTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Ink(
      width: AppSpacing.seatSize,
      height: AppSpacing.seatSize,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.r8),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drive_eta_rounded, color: AppColors.textSecondary, size: 20),
            const SizedBox(height: 2),
            Text(
              'C',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _SeatLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item({
      required Widget icon,
      required String label,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        item(
          icon: const _LegendBox(
            bg: AppColors.seatOkBg,
            border: AppColors.success,
            fg: AppColors.success,
            label: '1',
          ),
          label: 'Disponible',
        ),
        item(
          icon: const _LegendBox(
            bg: AppColors.infoSurface,
            border: AppColors.primaryBlue,
            fg: AppColors.primaryBlue,
            label: '1',
          ),
          label: 'Seleccionado',
        ),
        item(
          icon: const _LegendBox(
            bg: AppColors.fieldFill,
            border: AppColors.border,
            fg: AppColors.textSecondary,
            label: '1',
          ),
          label: 'Ocupado',
        ),
        item(
          icon: const _LegendDriverBox(),
          label: 'Conductor',
        ),
      ],
    );
  }
}

class _LegendBox extends StatelessWidget {
  const _LegendBox({
    required this.bg,
    required this.border,
    required this.fg,
    required this.label,
  });

  final Color bg;
  final Color border;
  final Color fg;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r8),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _LegendDriverBox extends StatelessWidget {
  const _LegendDriverBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.r8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Icon(Icons.drive_eta_rounded, size: 18, color: AppColors.textSecondary),
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
