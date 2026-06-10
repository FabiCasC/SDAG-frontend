import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart' hide SeatMapWidget;
import '../providers/reserva_provider.dart';

// IMPORTS DEL MAPA
import '../../../shared/widgets/mapa_ruta_widget.dart';
import '../../../data/models/route_polyline_model.dart';

class SeatMapScreen extends ConsumerStatefulWidget {
  const SeatMapScreen({
    required this.driverId,
    required this.tripId,
    super.key,
  });

  final String? driverId;
  final String? tripId;

  @override
  ConsumerState<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends ConsumerState<SeatMapScreen> {
  bool _initScheduled = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservaProvider);
    final controller = ref.read(reservaProvider.notifier);
    final stateDriver = state.conductorSeleccionado;
    final hasMatchingStateDriver = stateDriver != null &&
        ((widget.tripId != null && stateDriver.tripId == widget.tripId) ||
            (widget.driverId != null && stateDriver.driverId == widget.driverId));
    final fallbackAsync = ref.watch(_seatMapDriverProvider(_SeatMapLookup(
      driverId: widget.driverId,
      tripId: widget.tripId,
    )));

    if (hasMatchingStateDriver) {
      return _buildLoaded(
        context: context,
        ref: ref,
        controller: controller,
        driver: stateDriver,
        state: state,
        fallbackAsync: fallbackAsync,
      );
    }

    return fallbackAsync.when(
      loading: () => const AppScaffold(
        title: 'Seleccionar asientos',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppScaffold(
        title: 'Seleccionar asientos',
        body: PlaceholderPage(
          title: 'No se pudo cargar el viaje',
          subtitle: error.toString(),
        ),
      ),
      data: (driver) {
        if (!_initScheduled) {
          _initScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.startWithDriver(driver);
          });
        }
        return _buildLoaded(
          context: context,
          ref: ref,
          controller: controller,
          driver: driver,
          state: state,
          fallbackAsync: fallbackAsync,
        );
      },
    );
  }

  Widget _buildLoaded({
    required BuildContext context,
    required WidgetRef ref,
    required ReservaController controller,
    required ReservaDriverInfo driver,
    required ReservaState state,
    required AsyncValue<ReservaDriverInfo> fallbackAsync,
  }) {
    final occupiedAsync = ref.watch(occupiedSeatsByTripProvider(driver.tripId));
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
                // 1. Tarjeta superior del Conductor
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

                // 2. MAPA REAL EN VIVO (Ahora está arriba del todo)
                Text(
                  'Ruta del viaje',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 200, // Altura para que se vea claro y cómodo
                  width: double.infinity,
                  child: fallbackAsync.maybeWhen(
                    data: (driverInfo) {
                      final mockJson = {
                        "points": [
                          {"lat": -12.0961, "lng": -77.0315},
                          {"lat": -12.0553, "lng": -76.9631},
                          {"lat": -12.0239, "lng": -76.9012},
                          {"lat": -11.9392, "lng": -76.7024}
                        ]
                      };
                      return MapaRutaWidget(
                        routePolyline: RoutePolyline.fromJson(mockJson),
                      );
                    },
                    orElse: () => const Center(child: CircularProgressIndicator()),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 3. Distribución de asientos original
                Text(
                  'Elige tus asientos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _VehicleLayout(
                  totalSeats: driver.totalSeats,
                  occupiedSeats: occupiedSeats.toList()..sort(),
                  selectedSeats: state.asientosSeleccionados,
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

class _VehicleLayout extends StatelessWidget {
  const _VehicleLayout({
    required this.totalSeats,
    required this.occupiedSeats,
    required this.selectedSeats,
    required this.onSeatTapped,
  });

  final int totalSeats;
  final List<int> occupiedSeats;
  final List<int> selectedSeats;
  final ValueChanged<int> onSeatTapped;

  @override
  Widget build(BuildContext context) {
    final occupied = occupiedSeats.toSet();
    final selected = selectedSeats.toSet();

    Widget passengerSeat(int seatNumber) {
      final visualState = occupied.contains(seatNumber)
          ? _SeatVisualState.occupied
          : selected.contains(seatNumber)
          ? _SeatVisualState.selected
          : _SeatVisualState.available;

      final enabled = visualState != _SeatVisualState.occupied;

      return _SeatTile(
        seatNumber: seatNumber,
        state: visualState,
        enabled: enabled,
        onTap: () => onSeatTapped(seatNumber),
      );
    }

    Widget driverSeat() => const _DriverSeatTile();

    Widget twoColumnRow(Widget left, Widget right) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: right),
        ],
      );
    }

    Widget threeColumnRow(Widget left, Widget middle, Widget right) {
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

    Widget aisleRow(Widget left, Widget right) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: right),
        ],
      );
    }

    Widget emptySeat() => const SizedBox(
      width: AppSpacing.seatSize,
      height: AppSpacing.seatSize,
    );

    List<Widget> rows = [];

    void addRow(Widget row) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: AppSpacing.md));
      }
      rows.add(row);
    }

    switch (totalSeats) {
      case 4:
        addRow(twoColumnRow(driverSeat(), passengerSeat(1)));
        addRow(threeColumnRow(passengerSeat(2), passengerSeat(3), passengerSeat(4)));
        break;
      case 6:
        addRow(twoColumnRow(driverSeat(), passengerSeat(1)));
        addRow(twoColumnRow(passengerSeat(2), passengerSeat(3)));
        addRow(threeColumnRow(passengerSeat(4), passengerSeat(5), passengerSeat(6)));
        break;
      case 8:
        addRow(twoColumnRow(driverSeat(), passengerSeat(1)));
        addRow(twoColumnRow(passengerSeat(2), passengerSeat(3)));
        addRow(twoColumnRow(passengerSeat(4), passengerSeat(5)));
        addRow(threeColumnRow(passengerSeat(6), passengerSeat(7), passengerSeat(8)));
        break;
      case 14:
      case 15:
        addRow(twoColumnRow(driverSeat(), passengerSeat(1)));
        for (var seat = 2; seat <= totalSeats; seat += 2) {
          final rightSeatNumber = seat + 1;
          addRow(
            aisleRow(
              passengerSeat(seat),
              rightSeatNumber <= totalSeats ? passengerSeat(rightSeatNumber) : emptySeat(),
            ),
          );
        }
        break;
      default:
        addRow(twoColumnRow(driverSeat(), totalSeats >= 1 ? passengerSeat(1) : emptySeat()));
        for (var seat = 2; seat <= totalSeats; seat += 2) {
          final rightSeatNumber = seat + 1;
          addRow(
            twoColumnRow(
              passengerSeat(seat),
              rightSeatNumber <= totalSeats ? passengerSeat(rightSeatNumber) : emptySeat(),
            ),
          );
        }
        break;
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
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Distribución del vehículo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...rows,
            ],
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
      _SeatVisualState.occupied => (AppColors.seatBadBg, AppColors.error, AppColors.error),
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
          border: Border.all(color: border, width: 1.4),
        ),
        child: Center(
          child: Text(
            '$seatNumber',
            style: theme.textTheme.titleMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
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
            bg: AppColors.seatBadBg,
            border: AppColors.error,
            fg: AppColors.error,
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

final _seatMapDriverProvider =
FutureProvider.autoDispose.family<ReservaDriverInfo, _SeatMapLookup>((ref, lookup) async {
  final client = Supabase.instance.client;
  dynamic response;

  if (lookup.tripId != null && lookup.tripId!.trim().isNotEmpty) {
    response = await client
        .from('trips')
        .select('''
          id,
          status,
          drivers (
            id,
            plate,
            vehicle_type,
            capacity,
            estado,
            rating_avg,
            rating_count,
            profiles (
              name,
              first_name,
              last_name
            )
          ),
          routes (
            name,
            from_label,
            to_label,
            polyline
          )
        ''')
        .eq('id', lookup.tripId!)
        .single();
  } else if (lookup.driverId != null && lookup.driverId!.trim().isNotEmpty) {
    response = await client
        .from('trips')
        .select('''
          id,
          status,
          drivers!inner (
            id,
            plate,
            vehicle_type,
            capacity,
            estado,
            rating_avg,
            rating_count,
            profiles (
              name,
              first_name,
              last_name
            )
          ),
          routes (
            name,
            from_label,
            to_label,
            polyline
          )
        ''')
        .eq('driver_id', lookup.driverId!)
        .neq('status', 'completado')
        .neq('status', 'cancelado')
        .order('scheduled_departure_at', ascending: true)
        .limit(1)
        .single();
  } else {
    throw Exception('No se encontro el viaje seleccionado');
  }

  final row = Map<String, dynamic>.from(response as Map);
  final driver = row['drivers'];
  final route = row['routes'];

  if (driver is! Map || route is! Map) {
    throw Exception('Faltan datos del conductor o la ruta');
  }

  final driverMap = Map<String, dynamic>.from(driver);
  final routeMap = Map<String, dynamic>.from(route);
  final profile = driverMap['profiles'] is Map ? Map<String, dynamic>.from(driverMap['profiles'] as Map) : null;
  final firstName = profile?['first_name']?.toString().trim() ?? '';
  final lastName = profile?['last_name']?.toString().trim() ?? '';
  final fullName = '$firstName $lastName'.trim();
  final routeName = routeMap['name']?.toString().trim();
  final routeFrom = routeMap['from_label']?.toString().trim() ?? '';
  final routeTo = routeMap['to_label']?.toString().trim() ?? '';

  return ReservaDriverInfo(
    tripId: row['id'].toString(),
    driverId: driverMap['id'].toString(),
    name: (profile?['name']?.toString().trim().isNotEmpty ?? false)
        ? profile!['name'].toString().trim()
        : (fullName.isNotEmpty ? fullName : 'Conductor sin nombre'),
    plate: driverMap['plate']?.toString() ?? 'Sin placa',
    vehicleType: driverMap['vehicle_type']?.toString() ?? 'Vehiculo',
    totalSeats: (driverMap['capacity'] as int?) ?? 0,
    routeLabel: (routeName != null && routeName.isNotEmpty) ? routeName : '$routeFrom → $routeTo',
    rating: (driverMap['rating_avg'] as num?)?.toDouble() ?? 0,
    ratingCount: (driverMap['rating_count'] as int?) ?? 0,
    status: driverMap['estado']?.toString() ?? (row['status']?.toString() ?? ''),
  );
});

class _SeatMapLookup {
  const _SeatMapLookup({
    required this.driverId,
    required this.tripId,
  });

  final String? driverId;
  final String? tripId;

  @override
  bool operator ==(Object other) {
    return other is _SeatMapLookup &&
        other.driverId == driverId &&
        other.tripId == tripId;
  }

  @override
  int get hashCode => Object.hash(driverId, tripId);
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