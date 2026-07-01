import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';
import '../services/forced_departure_service.dart';
import '../utils/forced_departure_utils.dart';

class ForzarSalidaScreen extends ConsumerStatefulWidget {
  const ForzarSalidaScreen({super.key});

  @override
  ConsumerState<ForzarSalidaScreen> createState() => _ForzarSalidaScreenState();
}

class _ForzarSalidaScreenState extends ConsumerState<ForzarSalidaScreen> {
  final _service = ForcedDepartureService();
  Timer? _refreshTimer;

  bool _loading = true;
  bool _voting = false;
  bool _alreadyVoted = false;
  TripVoteSnapshot? _snapshot;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final reserva = ref.read(reservaProvider);
    final tripId = reserva.conductorSeleccionado?.tripId.trim();
    final userId = ref.read(passengerSessionProvider).account?.id;

    if (tripId == null || tripId.isEmpty) {
      if (!silent && mounted) {
        setState(() {
          _loading = false;
          _error = 'No hay viaje activo';
        });
      }
      return;
    }

    if (!silent && mounted) setState(() => _loading = true);

    try {
      final snap = await _service.loadTripSnapshot(tripId);
      var voted = false;
      if (userId != null) {
        final row = await Supabase.instance.client
            .from('reservations')
            .select('voted_early_departure')
            .eq('trip_id', tripId)
            .eq('passenger_profile_id', userId)
            .eq('status', 'activa')
            .maybeSingle();
        voted = row?['voted_early_departure'] == true;
      }

      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _alreadyVoted = voted;
        _loading = false;
        _error = snap == null ? 'No se pudo cargar el viaje' : null;
      });
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _vote() async {
    if (_voting || _alreadyVoted) return;
    final tripId = _snapshot?.tripId ?? ref.read(reservaProvider).conductorSeleccionado?.tripId;
    if (tripId == null || tripId.isEmpty) return;

    setState(() => _voting = true);
    final result = await _service.registerVote(tripId: tripId);
    if (!mounted) return;

    setState(() => _voting = false);

    if (!result.ok) {
      AppSnackbars.error(context, result.message);
      return;
    }

    setState(() => _alreadyVoted = true);
    await _load(silent: true);

    if (result.departureAuthorized) {
      AppSnackbars.success(context, '¡Salida anticipada autorizada! El viaje ha iniciado.');
      context.go(AppRoutes.passengerReservaActiva);
    } else {
      AppSnackbars.info(
        context,
        'Voto registrado: ${result.votos}/${result.totalPassengers} (se requiere 50%)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = ref.watch(reservaProvider);
    final driver = reserva.conductorSeleccionado;

    if (_loading) {
      return const AppScaffold(
        title: 'Forzar salida',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _snapshot == null || driver == null) {
      return AppScaffold(
        title: 'Forzar salida',
        body: PlaceholderPage(
          title: 'No disponible',
          subtitle: _error ?? 'Confirma una reserva activa para votar.',
        ),
      );
    }

    final snap = _snapshot!;
    final now = DateTime.now();
    final canVote = canVoteEarlyDeparture(
      tripStatus: snap.status,
      tripCreatedAt: snap.createdAt,
      now: now,
      alreadyVoted: _alreadyVoted,
    );
    final waitLeft = waitingMinutesRemaining(tripCreatedAt: snap.createdAt, now: now);
    final occupied = snap.passengerCount;
    final capacity = driver.totalSeats;
    final emptySeats = (capacity - occupied).clamp(0, capacity);

    return AppScaffold(
      title: 'Votar salida anticipada',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Si el vehículo lleva más de 10 minutos esperando, puedes votar para salir antes de llenarse.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(label: 'Asientos vacíos', value: '$emptySeats'),
                  const SizedBox(height: AppSpacing.sm),
                  _StatRow(
                    label: 'Votos registrados',
                    value: '${snap.votos} / ${snap.passengerCount} (mín. ${snap.threshold})',
                    strong: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatRow(
                    label: 'Estado del viaje',
                    value: snap.status,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (waitLeft > 0)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.infoSurface,
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
              child: Text(
                'Podrás votar en $waitLeft min (espera mínima de 10 min)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            )
          else if (_alreadyVoted)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.seatOkBg,
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
              child: const Text('✓ Ya registraste tu voto'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: canVote && !_voting ? _vote : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.energeticOrange,
              minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            ),
            child: _voting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : const Text('Votar por salida anticipada'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
