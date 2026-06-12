import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_navigation_back.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(passengerTripHistoryProvider);

    return Column(
      children: [
        Material(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: SafeArea(
            bottom: false,
            child: AppBar(
              leading: AppBarLeadingBack(fallbackRoute: AppRoutes.passengerHome),
              title: const Text('Mis viajes'),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
        ),
        Expanded(
          child: tripsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _HistoryError(message: error.toString()),
            data: (trips) {
              if (trips.isEmpty) return const _EmptyHistory();
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.p20),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final t = trips[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _TripCard(
                      trip: t,
                      onTap: () => context.push('${AppRoutes.passengerTripDetail}?id=${t.id}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final _PassengerTripHistoryItem trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (chipBg, chipFg, chipLabel, icon) = _statusVisual(trip.status);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
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
              Row(
                children: [
                  Icon(icon, color: chipFg),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      trip.dateLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      chipLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: chipFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                trip.routeLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${trip.driverName} · ${trip.plate} · Asientos ${trip.seatsLabel}',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'S/ ${trip.amount.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    trip.statusLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(color: chipFg),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final passengerTripHistoryProvider =
    FutureProvider.autoDispose<List<_PassengerTripHistoryItem>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return const <_PassengerTripHistoryItem>[];

  final reservas = await Supabase.instance.client
      .from('reservations')
      .select('''
        id, seats, pickup_point, status, amount, created_at,
        trips(
          id, status, started_at, finished_at,
          routes(name, from_label, to_label),
          drivers(plate, profiles(name, first_name, last_name))
        )
      ''')
      .eq('passenger_profile_id', userId)
      .inFilter('status', ['completada', 'cancelada'])
      .order('created_at', ascending: false);

  return (reservas as List)
      .cast<Map<String, dynamic>>()
      .map(_PassengerTripHistoryItem.fromMap)
      .toList();
});

class _PassengerTripHistoryItem {
  const _PassengerTripHistoryItem({
    required this.id,
    required this.dateLabel,
    required this.routeLabel,
    required this.driverName,
    required this.plate,
    required this.seats,
    required this.amount,
    required this.status,
  });

  final String id;
  final String dateLabel;
  final String routeLabel;
  final String driverName;
  final String plate;
  final List<int> seats;
  final double amount;
  final String status;

  String get seatsLabel => seats.isEmpty ? '-' : seats.map((seat) => '#$seat').join(', ');

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'cancelada':
        return 'Cancelado';
      case 'completada':
      case 'completado':
        return 'Completado';
      case 'activa':
      default:
        return 'Activo';
    }
  }

  factory _PassengerTripHistoryItem.fromMap(Map<String, dynamic> map) {
    final trip = map['trips'] is Map ? Map<String, dynamic>.from(map['trips'] as Map) : <String, dynamic>{};
    final route = trip['routes'] is Map ? Map<String, dynamic>.from(trip['routes'] as Map) : <String, dynamic>{};
    final driver = trip['drivers'] is Map ? Map<String, dynamic>.from(trip['drivers'] as Map) : <String, dynamic>{};
    final profile = driver['profiles'] is Map ? Map<String, dynamic>.from(driver['profiles'] as Map) : <String, dynamic>{};

    final firstName = profile['first_name']?.toString().trim() ?? '';
    final lastName = profile['last_name']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final routeName = route['name']?.toString().trim();
    final fromLabel = route['from_label']?.toString().trim() ?? '';
    final toLabel = route['to_label']?.toString().trim() ?? '';
    final createdAtRaw = trip['finished_at']?.toString() ??
        trip['started_at']?.toString() ??
        map['created_at']?.toString() ??
        '';

    return _PassengerTripHistoryItem(
      id: map['id'].toString(),
      dateLabel: _formatDate(createdAtRaw),
      routeLabel: (routeName != null && routeName.isNotEmpty) ? routeName : '$fromLabel → $toLabel',
      driverName: (profile['name']?.toString().trim().isNotEmpty ?? false)
          ? profile['name'].toString().trim()
          : (fullName.isNotEmpty ? fullName : 'Conductor sin nombre'),
      plate: driver['plate']?.toString() ?? 'Sin placa',
      seats: _parseSeats(map['seats']),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? '',
    );
  }
}

List<int> _parseSeats(dynamic rawSeats) {
  if (rawSeats is! List) return const [];
  final out = <int>[];
  for (final seat in rawSeats) {
    if (seat is int) {
      out.add(seat);
    } else if (seat is num) {
      out.add(seat.toInt());
    } else {
      final parsed = int.tryParse(seat.toString());
      if (parsed != null) out.add(parsed);
    }
  }
  out.sort();
  return out;
}

String _formatDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return 'Fecha no disponible';
  final local = parsed.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final yyyy = local.year.toString();
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$dd/$mm/$yyyy $hh:$min';
}

(Color, Color, String, IconData) _statusVisual(String status) {
  switch (status.toLowerCase()) {
    case 'cancelada':
      return (AppColors.seatBadBg, AppColors.error, 'Cancelado', Icons.cancel_rounded);
    case 'completada':
    case 'completado':
      return (AppColors.seatOkBg, AppColors.success, 'Completado', Icons.check_circle_rounded);
    case 'activa':
    default:
      return (AppColors.infoSurface, AppColors.primaryBlue, 'Activo', Icons.directions_bus_rounded);
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_bus_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes viajes registrados',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No se pudo cargar tu historial',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
