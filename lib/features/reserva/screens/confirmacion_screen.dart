import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/maps/google_eta_service.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

class ConfirmacionScreen extends ConsumerStatefulWidget {
  const ConfirmacionScreen({super.key});

  @override
  ConsumerState<ConfirmacionScreen> createState() => _ConfirmacionScreenState();
}

class _ConfirmacionScreenState extends ConsumerState<ConfirmacionScreen> {
  bool _showCheck = false;
  int? _etaMinutos;
  bool _etaLoading = true;
  bool _boardingSetupDone = false;
  StreamSubscription<List<Map<String, dynamic>>>? _boardingSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showCheck = true);
      _calcularEtaInicial();
      _setupAbordajeRealtime();
    });
  }

  void _setupAbordajeRealtime() {
    if (_boardingSetupDone) return;
    final reserva = ref.read(reservaProvider);
    final reservaId = reserva.reservaId;
    if (reservaId == null || reservaId.isEmpty) return;
    _boardingSetupDone = true;
    unawaited(_verificarAbordajeInicial(reservaId));
    _suscribirAbordaje(reservaId);
  }

  Future<void> _verificarAbordajeInicial(String reservaId) async {
    try {
      final entry = await Supabase.instance.client
          .from('manifest_entries')
          .select('boarding_status')
          .eq('reservation_id', reservaId)
          .limit(1)
          .maybeSingle();
      debugPrint('[Pasajero] verificación inicial: $entry');
      if (entry != null && entry['boarding_status']?.toString() == 'abordo' && mounted) {
        _navegarAViajeEnCurso(reservaId);
      }
    } catch (e) {
      debugPrint('[Pasajero] Error verificando abordaje inicial: $e');
    }
  }

  void _suscribirAbordaje(String reservaId) {
    _boardingSubscription?.cancel();
    _boardingSubscription = Supabase.instance.client
        .from('manifest_entries')
        .stream(primaryKey: ['id'])
        .eq('reservation_id', reservaId)
        .listen((data) {
      debugPrint('[Pasajero] manifest_entries stream: $data');
      if (!mounted || data.isEmpty) return;
      final status = data[0]['boarding_status']?.toString();
      debugPrint('[Pasajero] boarding_status=$status');
      if (status == 'abordo') {
        _navegarAViajeEnCurso(reservaId);
      }
    });
  }

  void _navegarAViajeEnCurso(String reservaId) {
    _boardingSubscription?.cancel();
    final reserva = ref.read(reservaProvider);
    final tripId = reserva.conductorSeleccionado?.tripId ?? '';
    final driverId = reserva.conductorSeleccionado?.driverId ?? '';
    final params = <String>[
      'reservaId=$reservaId',
      if (tripId.isNotEmpty) 'tripId=$tripId',
      if (driverId.isNotEmpty) 'driverId=$driverId',
    ].join('&');
    context.go('${AppRoutes.passengerViajeEnCurso}?$params');
  }

  @override
  void dispose() {
    _boardingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _calcularEtaInicial() async {
    final reserva = ref.read(reservaProvider);
    final driver = reserva.conductorSeleccionado;
    final pickup = reserva.puntoRecojo?.trim();

    if (driver == null || pickup == null || pickup.isEmpty) {
      if (!mounted) return;
      setState(() {
        _etaLoading = false;
        _etaMinutos = null;
      });
      return;
    }

    final eta = await GoogleEtaService.calcularEtaConductorAlPickup(
      driverId: driver.driverId,
      pickupAddress: pickup,
      pickupLat: reserva.pickupLat,
      pickupLng: reserva.pickupLng,
    );

    if (!mounted) return;
    setState(() {
      _etaMinutos = eta;
      _etaLoading = false;
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
    final pickup = reserva.puntoRecojo?.trim();
    final total = seats.length * 15.0;

    if (driver == null || reservaId == null || seats.isEmpty) {
      return const AppScaffold(
        title: 'Confirmación',
        body: PlaceholderPage(
          title: 'No hay una reserva confirmada',
          subtitle: 'Completa el pago para generar los QRs.',
        ),
      );
    }

    final titularName = _displayName(session.account?.name, fallback: 'Titular');

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
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${driver.name} · ${driver.plate}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Asientos: ${seats.map((s) => '#$s').join(', ')}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Punto de recojo: ${pickup == null || pickup.isEmpty ? '—' : pickup}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Monto pagado: S/ ${total.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_etaLoading)
                      Text(
                        'Calculando ETA...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (_etaMinutos != null)
                      Text(
                        'El conductor llegará en aproximadamente ≈ $_etaMinutos min',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else
                      Text(
                        'ETA no disponible',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: seats.length,
              itemBuilder: (context, index) {
                final asiento = seats[index];
                final qrData = '$reservaId|$asiento';
                final companion = index > 0 ? reserva.acompanantes[asiento] : null;
                final nombre = index == 0
                    ? titularName
                    : _displayName(companion?.fullName, fallback: 'Acompanante');
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _QrSeatCard(
                    reservaId: reservaId,
                    seatNumber: asiento,
                    passengerName: nombre,
                    qrData: qrData,
                    isCompanion: index > 0,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Ver mi reserva activa',
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

class _QrSeatCard extends StatelessWidget {
  const _QrSeatCard({
    required this.reservaId,
    required this.seatNumber,
    required this.passengerName,
    required this.qrData,
    required this.isCompanion,
  });

  final String reservaId;
  final int seatNumber;
  final String passengerName;
  final String qrData;
  final bool isCompanion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    debugPrint('[QR Generado] data="$qrData"');
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
            Text(
              'Asiento #$seatNumber',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 180.0,
                backgroundColor: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              passengerName,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
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
            if (isCompanion) ...[
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: 'Compartir QR',
                onPressed: () {
                  AppSnackbars.info(context, 'QR compartido con $passengerName');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
