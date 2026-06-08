import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

enum _Acceptance { accepted, pending, rejected }

class ForzarSalidaScreen extends ConsumerStatefulWidget {
  const ForzarSalidaScreen({super.key});

  @override
  ConsumerState<ForzarSalidaScreen> createState() => _ForzarSalidaScreenState();
}

class _ForzarSalidaScreenState extends ConsumerState<ForzarSalidaScreen> {
  Timer? _countdownTimer;
  Timer? _autoAcceptTimer;

  int _secondsLeft = 60;
  bool _authorizedShown = false;

  final Map<String, _Acceptance> _statusByPassengerId = {};

  @override
  void initState() {
    super.initState();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) return;
      setState(() => _secondsLeft -= 1);
    });

    _autoAcceptTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        for (final k in _statusByPassengerId.keys) {
          _statusByPassengerId[k] = _Acceptance.accepted;
        }
      });
      _checkAllAccepted();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoAcceptTimer?.cancel();
    super.dispose();
  }

  void _seedIfNeeded(List<_PassengerItem> items) {
    if (_statusByPassengerId.isNotEmpty) return;
    for (final p in items) {
      _statusByPassengerId[p.id] = p.isTitular ? _Acceptance.accepted : _Acceptance.pending;
    }
  }

  Future<void> _checkAllAccepted() async {
    if (_authorizedShown) return;
    final allAccepted =
        _statusByPassengerId.isNotEmpty && _statusByPassengerId.values.every((v) => v == _Acceptance.accepted);
    if (!allAccepted) return;

    _authorizedShown = true;
    final reserva = ref.read(reservaProvider);
    final seats = [...reserva.asientosSeleccionados]..sort();
    final additionalPerPassenger = 3.0;
    final additionalTotal = seats.length * additionalPerPassenger;
    ref.read(reservaProvider.notifier).requestAdditionalCharge(additionalTotal);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¡Salida autorizada!'),
          content: const Text('Todos los pasajeros aceptaron la salida anticipada.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continuar al pago'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    context.go('${AppRoutes.passengerPago}?mode=additional');
  }

  @override
  Widget build(BuildContext context) {
    final reserva = ref.watch(reservaProvider);
    final driver = reserva.conductorSeleccionado;
    final seats = [...reserva.asientosSeleccionados]..sort();

    if (driver == null || reserva.reservaId == null || seats.isEmpty) {
      return const AppScaffold(
        title: 'Forzar salida',
        body: PlaceholderPage(
          title: 'No hay reserva activa',
          subtitle: 'Confirma una reserva para poder solicitar salida anticipada.',
        ),
      );
    }

    final passengers = _buildPassengers(reserva);
    _seedIfNeeded(passengers);

    final emptySeats = (driver.totalSeats - seats.length).clamp(0, driver.totalSeats);
    final additionalPerPassenger = 3.0;
    final additionalTotal = seats.length * additionalPerPassenger;

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAllAccepted());

    return AppScaffold(
      title: 'Forzar salida anticipada',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Si el vehículo sale antes de llenarse, se calcula un pago proporcional adicional entre los pasajeros.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(label: 'Asientos vacíos restantes', value: '$emptySeats'),
                  const SizedBox(height: AppSpacing.sm),
                  _StatRow(
                    label: 'Costo adicional por pasajero',
                    value: 'S/ ${additionalPerPassenger.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatRow(
                    label: 'Total a pagar adicional',
                    value: 'S/ ${additionalTotal.toStringAsFixed(0)}',
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tiempo restante: $_secondsLeft s',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView(
              children: [
                ...passengers.map((p) {
                  final status = _statusByPassengerId[p.id] ?? _Acceptance.pending;
                  final (icon, color, label) = switch (status) {
                    _Acceptance.accepted => (Icons.check_circle_rounded, AppColors.success, 'Aceptó'),
                    _Acceptance.pending => (Icons.hourglass_top_rounded, AppColors.warning, 'Pendiente'),
                    _Acceptance.rejected => (Icons.cancel_rounded, AppColors.error, 'Rechazó'),
                  };

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(icon, color: color),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${p.name} · Asiento #${p.seat}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar solicitud'),
          ),
        ],
      ),
    );
  }

  List<_PassengerItem> _buildPassengers(ReservaState reserva) {
    final seats = [...reserva.asientosSeleccionados]..sort();
    final list = <_PassengerItem>[];
    if (seats.isEmpty) return list;

    list.add(_PassengerItem(id: 'titular', name: 'Titular', seat: seats.first, isTitular: true));
    for (final seat in seats.skip(1)) {
      final a = reserva.acompanantes[seat];
      list.add(
        _PassengerItem(
          id: 'acom_$seat',
          name: (a?.fullName.trim().isNotEmpty ?? false) ? a!.fullName.trim() : 'Acompañante',
          seat: seat,
          isTitular: false,
        ),
      );
    }
    return list;
  }
}

class _PassengerItem {
  const _PassengerItem({
    required this.id,
    required this.name,
    required this.seat,
    required this.isTitular,
  });

  final String id;
  final String name;
  final int seat;
  final bool isTitular;
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
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: strong ? AppColors.primaryBlue : AppColors.textPrimary,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
