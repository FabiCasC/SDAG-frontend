import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/conductor_comisiones_provider.dart';

enum _TripStatus { completado, enRuta }

class _ConductorTripHistoryItem {
  const _ConductorTripHistoryItem({
    required this.id,
    required this.dateLabel,
    required this.rutaLabel,
    required this.status,
    required this.totalRecaudado,
  });

  final String id;
  final String dateLabel;
  final String rutaLabel;
  final _TripStatus status;
  final double totalRecaudado;
}

class ConductorHistorialScreen extends ConsumerWidget {
  const ConductorHistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = ref.watch(conductorComisionesProvider).porcentajeComision;
    final tripsAsync = ref.watch(_conductorMisViajesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mis viajes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Text(
              'No se pudo cargar los viajes: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) return const _Empty();
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.p20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final t = items[index];
              final total = t.totalRecaudado;
              final comision = total * pct;
              final (chipBg, chipFg, chipLabel) = switch (t.status) {
                _TripStatus.completado => (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Completado'),
                _TripStatus.enRuta => (const Color(0xFFFFEDD5), const Color(0xFFF97316), 'En ruta'),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
                                'Comisión: S/ ${comision.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFFF97316),
                                      fontWeight: FontWeight.w900,
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
                      ],
                    ),
                  ),
                ),
              );
            },
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
              'Sin viajes registrados',
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

final _conductorMisViajesProvider = FutureProvider.autoDispose<List<_ConductorTripHistoryItem>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const [];

  final driver = await Supabase.instance.client.from('drivers').select('id').eq('profile_id', user.id).single();
  final driverId = driver['id']?.toString();
  if (driverId == null || driverId.isEmpty) return const [];

  final viajes = await Supabase.instance.client
      .from('trips')
      .select('id, status, started_at, finished_at, amount_total, routes(name)')
      .eq('driver_id', driverId)
      .inFilter('status', ['completado', 'en_ruta'])
      .order('created_at', ascending: false)
      .limit(10);

  final out = <_ConductorTripHistoryItem>[];
  for (final raw in (viajes as List).cast<Map<String, dynamic>>()) {
    final id = raw['id']?.toString();
    final statusRaw = raw['status']?.toString();
    final amount = (raw['amount_total'] as num?)?.toDouble() ?? 0.0;
    if (id == null || statusRaw == null) continue;

    final dt = DateTime.tryParse(raw['finished_at']?.toString() ?? '') ??
        DateTime.tryParse(raw['started_at']?.toString() ?? '');
    final dateLabel = dt == null ? '—' : _formatDateTime(dt);

    String routeLabel = 'Ruta';
    final routesRaw = raw['routes'];
    if (routesRaw is Map<String, dynamic>) {
      routeLabel = routesRaw['name']?.toString() ?? routeLabel;
    } else if (routesRaw is Map) {
      routeLabel = routesRaw.cast<String, dynamic>()['name']?.toString() ?? routeLabel;
    } else if (routesRaw is List && routesRaw.isNotEmpty) {
      final first = routesRaw.first;
      if (first is Map<String, dynamic>) {
        routeLabel = first['name']?.toString() ?? routeLabel;
      } else if (first is Map) {
        routeLabel = first.cast<String, dynamic>()['name']?.toString() ?? routeLabel;
      }
    }

    out.add(
      _ConductorTripHistoryItem(
        id: id,
        dateLabel: dateLabel,
        rutaLabel: routeLabel,
        status: statusRaw == 'en_ruta' ? _TripStatus.enRuta : _TripStatus.completado,
        totalRecaudado: amount,
      ),
    );
  }
  return out;
});

String _formatDateTime(DateTime dt) {
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final yyyy = dt.year.toString();
  final hh = dt.hour;
  final min = dt.minute.toString().padLeft(2, '0');
  final suffix = hh >= 12 ? 'PM' : 'AM';
  final hh12 = ((hh + 11) % 12) + 1;
  return '$dd/$mm/$yyyy · $hh12:$min $suffix';
}
