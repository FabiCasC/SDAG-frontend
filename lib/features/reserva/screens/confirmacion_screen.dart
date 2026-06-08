import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

class ConfirmacionScreen extends ConsumerStatefulWidget {
  const ConfirmacionScreen({super.key});

  @override
  ConsumerState<ConfirmacionScreen> createState() => _ConfirmacionScreenState();
}

class _ConfirmacionScreenState extends ConsumerState<ConfirmacionScreen> {
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showCheck = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reserva = ref.watch(reservaProvider);
    final session = ref.watch(passengerSessionProvider);

    final driver = reserva.conductorSeleccionado;
    final reservaId = reserva.reservaId;
    final seats = [...reserva.asientosSeleccionados]..sort();

    if (driver == null || reservaId == null || seats.isEmpty) {
      return const AppScaffold(
        title: 'Confirmación',
        body: PlaceholderPage(
          title: 'No hay una reserva confirmada',
          subtitle: 'Completa el pago para generar los QRs.',
        ),
      );
    }

    final titularId = session.account?.id ?? 'titular';
    final titularName = _displayName(session.account?.name, fallback: 'Titular');

    final passengers = <_QrPassenger>[
      _QrPassenger(
        passengerId: titularId,
        name: titularName,
        seatNumber: seats.first,
        isCompanion: false,
      ),
      ...seats.skip(1).map((seat) {
        final a = reserva.acompanantes[seat];
        return _QrPassenger(
          passengerId: 'acom_$seat',
          name: _displayName(a?.fullName, fallback: 'Acompañante'),
          seatNumber: seat,
          isCompanion: true,
        );
      }),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go(AppRoutes.passengerHome),
        ),
        title: const Text('Confirmación'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            Center(
              child: AnimatedScale(
                scale: _showCheck ? 1 : 0.6,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.seatOkBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 42),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '¡Reserva confirmada!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tu viaje está listo',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...passengers.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _QrCard(
                    reservaId: reservaId,
                    passenger: p,
                  ),
                )),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Ver mi reserva',
              onPressed: () => context.go(AppRoutes.passengerReservaActiva),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: 'Ir al inicio',
              onPressed: () => context.go(AppRoutes.passengerHome),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(String? value, {required String fallback}) {
    final v = value?.trim();
    return (v != null && v.isNotEmpty) ? v : fallback;
  }
}

class _QrPassenger {
  const _QrPassenger({
    required this.passengerId,
    required this.name,
    required this.seatNumber,
    required this.isCompanion,
  });

  final String passengerId;
  final String name;
  final int seatNumber;
  final bool isCompanion;
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.reservaId, required this.passenger});

  final String reservaId;
  final _QrPassenger passenger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = '$reservaId|${passenger.passengerId}|${passenger.seatNumber}';

    return DecoratedBox(
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
                size: 180,
                backgroundColor: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              passenger.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Asiento #${passenger.seatNumber}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.seatWarnBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Pendiente de abordaje',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (passenger.isCompanion) ...[
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: 'Compartir QR',
                onPressed: () {
                  AppSnackbars.info(context, 'QR compartido con ${passenger.name}');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
