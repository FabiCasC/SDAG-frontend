import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/conductor_comisiones_provider.dart';

enum _TripStatus { completado, cancelado }

class _ConductorTripHistoryItem {
  const _ConductorTripHistoryItem({
    required this.id,
    required this.dateLabel,
    required this.rutaLabel,
    required this.ocupados,
    required this.capacidad,
    required this.status,
    required this.abordaron,
    required this.ausentes,
  });

  final String id;
  final String dateLabel;
  final String rutaLabel;
  final int ocupados;
  final int capacidad;
  final _TripStatus status;
  final List<String> abordaron;
  final List<String> ausentes;

  double get totalRecaudado => ocupados * 15.0;
}

class ConductorHistorialScreen extends ConsumerWidget {
  const ConductorHistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = ref.watch(conductorComisionesProvider).porcentajeComision;
    final items = _mockHistory();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mis viajes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: items.isEmpty
          ? const _Empty()
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.p20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final t = items[index];
                final total = t.totalRecaudado;
                final comision = total * pct;
                final (chipBg, chipFg, chipLabel) = switch (t.status) {
                  _TripStatus.completado => (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Completado'),
                  _TripStatus.cancelado => (const Color(0xFFFEE2E2), const Color(0xFFDC2626), 'Cancelado'),
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    onTap: () => _showDetail(context, t, pct),
                    child: Container(
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
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.dateLabel,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: chipBg,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  chipLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: chipFg,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            t.rutaLabel,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${t.ocupados}/${t.capacidad} asientos ocupados',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Text(
                                'S/ ${total.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Comisión: S/ ${comision.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFFF97316),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    _ConductorTripHistoryItem trip,
    double pct,
  ) async {
    final total = trip.totalRecaudado;
    final comision = total * pct;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalle del viaje'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  trip.rutaLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  trip.dateLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Abordaron (${trip.abordaron.length})',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...trip.abordaron.map((p) => Text('• $p')),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ausentes (${trip.ausentes.length})',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (trip.ausentes.isEmpty) const Text('• Ninguno'),
                ...trip.ausentes.map((p) => Text('• $p')),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Total: S/ ${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Comisión (${(pct * 100).round()}%): S/ ${comision.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFF97316),
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no tienes viajes registrados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

List<_ConductorTripHistoryItem> _mockHistory() {
  return const [
    _ConductorTripHistoryItem(
      id: 'h1',
      dateLabel: '05/05/2025 · 7:30 AM',
      rutaLabel: 'San Isidro → Chosica',
      ocupados: 8,
      capacidad: 8,
      status: _TripStatus.completado,
      abordaron: [
        'Ana Pérez',
        'Luis Torres',
        'María García',
        'Pedro Salas',
        'Rosa Díaz',
        'Juan Quispe',
        'Pasajero 7',
        'Pasajero 8',
      ],
      ausentes: [],
    ),
    _ConductorTripHistoryItem(
      id: 'h2',
      dateLabel: '04/05/2025 · 6:45 PM',
      rutaLabel: 'Chosica → San Isidro',
      ocupados: 7,
      capacidad: 8,
      status: _TripStatus.completado,
      abordaron: [
        'Ana Pérez',
        'Luis Torres',
        'María García',
        'Pedro Salas',
        'Rosa Díaz',
        'Juan Quispe',
        'Pasajero 7',
      ],
      ausentes: ['Pasajero 8'],
    ),
    _ConductorTripHistoryItem(
      id: 'h3',
      dateLabel: '03/05/2025 · 8:05 AM',
      rutaLabel: 'San Isidro → Chosica',
      ocupados: 6,
      capacidad: 8,
      status: _TripStatus.cancelado,
      abordaron: [
        'Ana Pérez',
        'Luis Torres',
        'María García',
        'Pedro Salas',
        'Rosa Díaz',
        'Juan Quispe',
      ],
      ausentes: [],
    ),
  ];
}
