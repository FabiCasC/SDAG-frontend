import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/viaje_provider.dart';
import 'punto_alternativo_screen.dart';

class ReservaActivaScreen extends ConsumerStatefulWidget {
  const ReservaActivaScreen({super.key});

  @override
  ConsumerState<ReservaActivaScreen> createState() => _ReservaActivaScreenState();
}

class _ReservaActivaScreenState extends ConsumerState<ReservaActivaScreen> {
  bool _started = false;
  bool _sheetOpen = false;
  bool _extraPaidSnackShown = false;
  late final ProviderSubscription<ViajeState> _viajeSub;

  @override
  void initState() {
    super.initState();

    _viajeSub = ref.listenManual<ViajeState>(viajeProvider, (previous, next) {
      if (!mounted) return;

      if (next.finished && previous?.finished != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(AppRoutes.passengerCalificacion);
        });
        return;
      }

      if (next.showAlternativePickup &&
          previous?.showAlternativePickup != true &&
          !_sheetOpen) {
        final text = next.alternativePickupText ?? '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _openAlternativePickup(text);
        });
      }
    });
  }

  @override
  void dispose() {
    _viajeSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extraPaid = GoRouterState.of(context).uri.queryParameters['extraPaid'] == '1';
    if (extraPaid && !_extraPaidSnackShown) {
      _extraPaidSnackShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackbars.success(context, 'Pago adicional realizado');
      });
    }

    final reserva = ref.watch(reservaProvider);
    final viaje = ref.watch(viajeProvider);
    final controller = ref.read(viajeProvider.notifier);
    final session = ref.watch(passengerSessionProvider);

    final driver = reserva.conductorSeleccionado;
    final seats = [...reserva.asientosSeleccionados]..sort();

    if (driver == null || reserva.reservaId == null || seats.isEmpty) {
      return const AppScaffold(
        title: 'Mi viaje',
        body: PlaceholderPage(
          title: 'No tienes un viaje activo',
          subtitle: 'Completa una reserva para ver el viaje en curso.',
        ),
      );
    }

    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final driverId = reserva.conductorSeleccionado?.driverId;
        if (driverId != null && driverId.isNotEmpty) {
          controller.start(driverId);
        }
      });
    }

    final statusChip = _StatusChip(status: viaje.status);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi viaje'),
            Text(
              driver.plate,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (viaje.showArrivalBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.primaryBlue,
                child: Text(
                  '¡Tu conductor está llegando!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.p20),
                children: [
                  Row(
                    children: [
                      statusChip,
                      const Spacer(),
                      Text(
                        'ETA',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DriverCard(
                    name: driver.name,
                    plate: driver.plate,
                    rating: driver.rating,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TripCard(
                    pickup: reserva.puntoRecojo ?? '-',
                    seats: seats,
                    paid: reserva.montoTotal,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'El conductor llega en aproximadamente',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${viaje.etaMinutes} min',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - (AppSpacing.p20 * 2) - AppSpacing.sm) / 2,
                        child: _ActionButton(
                          label: 'Chat',
                          icon: Icons.chat_bubble_rounded,
                          onTap: () => context.push(AppRoutes.passengerChat),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - (AppSpacing.p20 * 2) - AppSpacing.sm) / 2,
                        child: _ActionButton(
                          label: 'Ver QR',
                          icon: Icons.qr_code_rounded,
                          onTap: () => _openQrSheet(
                            context,
                            reservaId: reserva.reservaId!,
                            seats: seats,
                            titularName: session.account?.name ?? 'Titular',
                            acompanantes: reserva.acompanantes,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - (AppSpacing.p20 * 2) - AppSpacing.sm) / 2,
                        child: _ActionButton(
                          label: 'Ubicación',
                          icon: Icons.location_on_rounded,
                          onTap: () => context.push(AppRoutes.passengerMapaViaje),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - (AppSpacing.p20 * 2) - AppSpacing.sm) / 2,
                        child: _ActionButton(
                          label: 'Espérame',
                          icon: Icons.hourglass_bottom_rounded,
                          onTap: () async {
                            final ok = await _confirmWait(context);
                            if (!context.mounted) return;
                            if (!ok) return;
                            AppSnackbars.warning(context, 'Señal enviada al conductor');
                          },
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - (AppSpacing.p20 * 2) - AppSpacing.sm) / 2,
                        child: _ActionButton(
                          label: 'Forzar salida',
                          icon: Icons.rocket_launch_rounded,
                          onTap: () => context.push(AppRoutes.passengerForzarSalida),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.passengerCancelarReserva),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Cancelar reserva'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAlternativePickup(String text) async {
    _sheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      builder: (context) {
        return PuntoAlternativoSheet(puntoAlternativo: text);
      },
    );
    if (!mounted) return;
    _sheetOpen = false;
    ref.read(viajeProvider.notifier).dismissAlternativePickup();
  }

  Future<bool> _confirmWait(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Espérame'),
          content: const Text('¿Deseas enviar una señal al conductor para que espere?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _ActiveQrPassenger {
  const _ActiveQrPassenger({
    required this.passengerId,
    required this.name,
    required this.seatNumber,
  });

  final String passengerId;
  final String name;
  final int seatNumber;
}

Future<void> _openQrSheet(
  BuildContext context, {
  required String reservaId,
  required List<int> seats,
  required String titularName,
  required Map<int, ReservaAcompanante> acompanantes,
}) async {
  final passengers = <_ActiveQrPassenger>[
    _ActiveQrPassenger(
      passengerId: 'titular',
      name: titularName,
      seatNumber: seats.first,
    ),
    ...seats.skip(1).map((seat) {
      final a = acompanantes[seat];
      return _ActiveQrPassenger(
        passengerId: 'acom_$seat',
        name: a?.fullName ?? 'Acompañante',
        seatNumber: seat,
      );
    }),
  ];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tus QR',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: passengers.length,
                  itemBuilder: (context, index) {
                    final p = passengers[index];
                    final qrData = '$reservaId|${p.passengerId}|${p.seatNumber}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DecoratedBox(
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
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: QrImageView(
                                  data: qrData,
                                  size: 160,
                                  backgroundColor: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                p.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Asiento #${p.seatNumber}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ViajeStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      ViajeStatus.esperandoConductor => (AppColors.seatWarnBg, AppColors.warning, 'Esperando conductor'),
      ViajeStatus.conductorEnCamino => (AppColors.infoSurface, AppColors.primaryBlue, 'Conductor en camino'),
      ViajeStatus.enRuta => (AppColors.seatOkBg, AppColors.success, 'En ruta'),
    };

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
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.name,
    required this.plate,
    required this.rating,
  });

  final String name;
  final String plate;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(name);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryTint12,
              child: Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    plate,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.ratingStar, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  rating.toStringAsFixed(1),
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
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
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.pickup,
    required this.seats,
    required this.paid,
  });

  final String pickup;
  final List<int> seats;
  final double paid;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(label: 'Recojo', value: pickup),
            const SizedBox(height: AppSpacing.sm),
            _Row(label: 'Asientos', value: seats.map((s) => '#$s').join(', ')),
            const SizedBox(height: AppSpacing.sm),
            _Row(label: 'Monto pagado', value: 'S/ ${paid.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        side: const BorderSide(color: AppColors.primaryBlue),
        minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
      ),
    );
  }
}
