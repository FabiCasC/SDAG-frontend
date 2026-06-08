import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({this.initialDirection, super.key});

  final String? initialDirection;

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  MockTripDirection? _direction;

  @override
  void initState() {
    super.initState();
    _direction = _parseDirection(widget.initialDirection);
  }

  MockTripDirection? _parseDirection(String? value) {
    return switch (value) {
      'si_cho' => MockTripDirection.sanIsidroToChosica,
      'cho_si' => MockTripDirection.chosicaToSanIsidro,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final drivers = _direction == null
        ? const <MockDriver>[]
        : MockData.drivers
            .where((d) => d.direction == _direction)
            .where(
              (d) =>
                  d.status == MockDriverStatus.available ||
                  d.status == MockDriverStatus.active,
            )
            .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        title: const Text('Buscar viaje'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            Text(
              'Selecciona dirección',
              style: theme.textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            _DirectionSelector(
              direction: _direction,
              onChanged: (value) => setState(() => _direction = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_direction == null)
              const PlaceholderPage(
                title: 'Elige una dirección',
                subtitle: 'Selecciona una dirección para ver conductores disponibles.',
              )
            else if (drivers.isEmpty)
              const _EmptyDriversState()
            else
              ...drivers.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _DriverCard(
                    driver: d,
                    onTap: () => context.push(
                      '${AppRoutes.passengerDriverDetail}?id=${d.id}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DirectionSelector extends StatelessWidget {
  const _DirectionSelector({
    required this.direction,
    required this.onChanged,
  });

  final MockTripDirection? direction;
  final ValueChanged<MockTripDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final leftSelected = direction == MockTripDirection.sanIsidroToChosica;
    final rightSelected = direction == MockTripDirection.chosicaToSanIsidro;

    return Row(
      children: [
        Expanded(
          child: _DirectionButton(
            selected: leftSelected,
            label: 'San Isidro → Chosica',
            onPressed: () => onChanged(MockTripDirection.sanIsidroToChosica),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _DirectionButton(
            selected: rightSelected,
            label: 'Chosica → San Isidro',
            onPressed: () => onChanged(MockTripDirection.chosicaToSanIsidro),
          ),
        ),
      ],
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = selected ? AppColors.primaryBlue : AppColors.white;
    final fg = selected ? AppColors.white : AppColors.primaryBlue;
    final border = BorderSide(color: AppColors.primaryBlue);

    return SizedBox(
      height: AppSpacing.controlHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver, required this.onTap});

  final MockDriver driver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(driver.name);

    final (seatBg, seatFg, seatLabel) = _seatBadge(driver.availableSeats);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryTint12,
                child: Text(
                  initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driver.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: i < driver.rating.round()
                                ? AppColors.ratingStar
                                : AppColors.fieldFill,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          driver.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _Badge(
                          bg: AppColors.fieldFill,
                          fg: AppColors.textPrimary,
                          label: driver.plate,
                        ),
                        _Badge(
                          bg: seatBg,
                          fg: seatFg,
                          label: seatLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.event_seat_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${driver.totalSeats} asientos',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(Icons.alt_route_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            driver.routeLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Llega en ~${driver.etaMinutes} min',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
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

  static (Color bg, Color fg, String label) _seatBadge(int available) {
    if (available >= 4) {
      return (AppColors.seatOkBg, AppColors.success, '$available disponibles');
    }
    if (available >= 2) {
      return (AppColors.seatWarnBg, AppColors.warning, '$available disponibles');
    }
    return (AppColors.seatBadBg, AppColors.error, '1 disponible');
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.bg, required this.fg, required this.label});

  final Color bg;
  final Color fg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyDriversState extends StatelessWidget {
  const _EmptyDriversState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_bus_filled_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay conductores disponibles',
              style: theme.textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Intenta cambiar la dirección o vuelve a intentarlo más tarde.',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
