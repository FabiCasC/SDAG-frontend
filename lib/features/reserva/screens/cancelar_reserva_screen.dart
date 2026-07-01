import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';
import '../services/reservation_refund_service.dart';
import '../utils/trip_rules.dart';

class CancelarReservaScreen extends ConsumerStatefulWidget {
  const CancelarReservaScreen({super.key});

  @override
  ConsumerState<CancelarReservaScreen> createState() => _CancelarReservaScreenState();
}

class _CancelarReservaScreenState extends ConsumerState<CancelarReservaScreen> {
  bool _cancelando = false;
  bool _loadingTrip = true;
  String? _tripStatus;
  String? _reservaIdLoaded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTripStatus());
  }

  Future<void> _loadTripStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loadingTrip = false);
      return;
    }

    final reserva = ref.read(reservaProvider);
    var reservaId = reserva.reservaId?.trim();
    var tripId = reserva.conductorSeleccionado?.tripId.trim();

    try {
      if (reservaId == null || reservaId.isEmpty) {
        final row = await Supabase.instance.client
            .from('reservations')
            .select('id, trip_id')
            .eq('passenger_profile_id', userId)
            .eq('status', 'activa')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        reservaId = row?['id']?.toString();
        tripId ??= row?['trip_id']?.toString();
      }

      _reservaIdLoaded = reservaId;

      if (tripId != null && tripId.isNotEmpty) {
        final trip = await Supabase.instance.client
            .from('trips')
            .select('status')
            .eq('id', tripId)
            .maybeSingle();
        final status = trip?['status']?.toString() ?? 'esperando';
        ref.read(reservaProvider.notifier).setVehiculoPartio(isTripDeparted(status));
        if (mounted) {
          setState(() {
            _tripStatus = status;
            _loadingTrip = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingTrip = false);
  }

  Future<void> _cancelarReserva() async {
    if (_cancelando) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Sesión inválida');
      return;
    }

    final reservaId = _reservaIdLoaded ?? ref.read(reservaProvider).reservaId?.trim();
    if (reservaId == null || reservaId.isEmpty) {
      if (!mounted) return;
      AppSnackbars.error(context, 'No se encontró una reserva activa');
      return;
    }

    if (_tripStatus != null && !canCancelReservationForTripStatus(_tripStatus!)) {
      if (!mounted) return;
      AppSnackbars.error(context, 'El vehículo ya partió. No se puede cancelar.');
      return;
    }

    setState(() => _cancelando = true);
    try {
      final result = await ReservationRefundService().cancelWithRefund(
        reservationId: reservaId,
        passengerProfileId: userId,
      );

      if (!result.success) {
        if (!mounted) return;
        AppSnackbars.error(context, result.message);
        return;
      }

      ref.read(reservaProvider.notifier).reset();

      if (!mounted) return;
      AppSnackbars.success(
        context,
        'Reserva cancelada. Reembolso procesado${result.refundId != null ? ' (${result.refundId})' : ''}.',
      );
      context.go(AppRoutes.passengerHome);
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'No se pudo cancelar la reserva');
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = ref.watch(reservaProvider);
    final blocked = _tripStatus != null
        ? !canCancelReservationForTripStatus(_tripStatus!)
        : reserva.vehiculoPartio;

    if (_loadingTrip) {
      return const AppScaffold(
        title: 'Cancelar reserva',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'Cancelar reserva',
      fallbackRoute: AppRoutes.passengerReservaActiva,
      body: blocked
          ? _VehicleDepartedCard(onClose: () => context.pop())
          : _CancelableCard(
              monto: reserva.montoTotal,
              cancelando: _cancelando,
              onConfirm: _cancelarReserva,
            ),
    );
  }
}

class _CancelableCard extends StatelessWidget {
  const _CancelableCard({
    required this.monto,
    required this.cancelando,
    required this.onConfirm,
  });

  final double monto;
  final bool cancelando;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.seatWarnBg,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Puedes cancelar mientras el viaje esté en espera. Se procesará el reembolso vía Culqi y quedará registrado en Supabase.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Monto a reembolsar:',
                    style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  'S/ ${monto.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          ),
          onPressed: cancelando ? null : onConfirm,
          child: cancelando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                )
              : const Text('Confirmar cancelación y reembolso'),
        ),
      ],
    );
  }
}

class _VehicleDepartedCard extends StatelessWidget {
  const _VehicleDepartedCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.seatBadBg,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.error),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'El vehículo ya partió',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'No es posible cancelar ni obtener reembolso una vez iniciado el viaje (status en_ruta).',
                      style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        AppSecondaryButton(label: 'Entendido', onPressed: onClose),
      ],
    );
  }
}
