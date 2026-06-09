import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import 'busqueda_service.dart';

class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({this.initialDirection, super.key});

  final String? initialDirection;

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  /// Dirección seleccionada: 'si_cho' o 'cho_si'
  String? _direction;

  /// Servicio que consulta viajes reales desde Supabase
  final BusquedaService _service = BusquedaService();

  /// Lista de viajes disponibles cargada desde Supabase
  List<ViajeDisponible> _viajes = [];

  /// Indica si se está cargando datos
  bool _cargando = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection;
    if (_direction != null) {
      _cargarViajes(_direction!);
    }
  }

  /// Consulta Supabase y actualiza la lista de viajes
  Future<void> _cargarViajes(String direction) async {
    setState(() => _cargando = true);
    try {
      final viajes = await _service.buscarViajes(direction);
      if (!mounted) return;
      setState(() {
        _viajes = viajes;
        _errorMessage = null;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viajes = [];
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DirectionSelector(
              direction: _direction,
              onChanged: (value) {
                setState(() {
                  _direction = value;
                  _viajes = [];
                  _errorMessage = null;
                });
                _cargarViajes(value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_direction == null)
              const PlaceholderPage(
                title: 'Elige una dirección',
                subtitle: 'Selecciona una dirección para ver conductores disponibles.',
              )
            else if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _ErrorDriversState(message: _errorMessage!)
            else if (_viajes.isEmpty)
              const _EmptyDriversState()
            else
              ..._viajes.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _DriverCard(
                    viaje: v,
                    onTap: () => context.push(
                      '${AppRoutes.passengerDriverDetail}?id=${v.driverId}&tripId=${v.tripId}',
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

  final String? direction;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final leftSelected = direction == 'si_cho';
    final rightSelected = direction == 'cho_si';

    return Row(
      children: [
        Expanded(
          child: _DirectionButton(
            selected: leftSelected,
            label: 'San Isidro → Chosica',
            onPressed: () => onChanged('si_cho'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _DirectionButton(
            selected: rightSelected,
            label: 'Chosica → San Isidro',
            onPressed: () => onChanged('cho_si'),
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

    return SizedBox(
      height: AppSpacing.controlHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: const BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.viaje, required this.onTap});

  final ViajeDisponible viaje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(viaje.driverName);
    final (seatBg, seatFg, seatLabel) = _seatBadge(viaje.availableSeats);
    final (statusBg, statusFg, statusLabel) = _statusBadge(viaje.status);

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
                            viaje.driverName,
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
                            color: i < viaje.rating.round()
                                ? AppColors.ratingStar
                                : AppColors.fieldFill,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          viaje.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
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
                          label: viaje.plate,
                        ),
                        _Badge(
                          bg: seatBg,
                          fg: seatFg,
                          label: seatLabel,
                        ),
                        _Badge(
                          bg: statusBg,
                          fg: statusFg,
                          label: statusLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_seat_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${viaje.totalSeats} asientos · ${viaje.vehicleType}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(
                          Icons.alt_route_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            viaje.routeLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
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

  static (Color bg, Color fg, String label) _statusBadge(String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case 'ocupado':
        return (AppColors.seatWarnBg, AppColors.warning, 'Ocupado');
      case 'en_ruta':
      case 'en ruta':
        return (AppColors.infoSurface, AppColors.primaryBlue, 'En ruta');
      case 'disponible':
      default:
        return (AppColors.seatOkBg, AppColors.success, 'Disponible');
    }
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
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
            const Icon(
              Icons.directions_bus_filled_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay conductores disponibles',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Intenta cambiar la dirección o vuelve a intentarlo más tarde.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorDriversState extends StatelessWidget {
  const _ErrorDriversState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No se pudo cargar la busqueda',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
