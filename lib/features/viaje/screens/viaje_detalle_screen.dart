import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class ViajeDetalleScreen extends StatelessWidget {
  const ViajeDetalleScreen({required this.tripId, super.key});

  final String? tripId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detalle del viaje',
      body: FutureBuilder<_TripDetailItem?>(
        future: _loadTrip(tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return PlaceholderPage(
              title: 'No se pudo cargar el viaje',
              subtitle: snapshot.error.toString(),
            );
          }

          final trip = snapshot.data;
          if (trip == null) {
            return const PlaceholderPage(
              title: 'Viaje no encontrado',
              subtitle: 'Vuelve al historial para seleccionar otro viaje.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              Text(
                trip.dateLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Line(label: 'Conductor', value: '${trip.driverName} · ${trip.plate}'),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(label: 'Ruta', value: trip.routeLabel),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(label: 'Recojo', value: trip.pickupPoint),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(label: 'Asientos', value: trip.seatsLabel),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(label: 'Monto', value: 'S/ ${trip.amount.toStringAsFixed(2)}'),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(label: 'Estado', value: trip.statusLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DashedBorderCard(
                borderColor: AppColors.primaryBlue,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Line(label: 'Reserva', value: trip.id),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(label: 'Fecha', value: trip.dateLabel),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(label: 'Total', value: 'S/ ${trip.amount.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
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

class _DashedBorderCard extends StatelessWidget {
  const _DashedBorderCard({
    required this.borderColor,
    required this.child,
  });

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: borderColor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(AppRadius.r16),
    );

    const dash = 6.0;
    const gap = 4.0;

    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

Future<_TripDetailItem?> _loadTrip(String? tripId) async {
  if (tripId == null || tripId.trim().isEmpty) return null;
  final row = await Supabase.instance.client
      .from('reservations')
      .select('*, trips(*, routes(*), drivers(*, profiles(*)))')
      .eq('id', tripId)
      .maybeSingle();
  if (row == null) return null;
  return _TripDetailItem.fromMap(Map<String, dynamic>.from(row));
}

class _TripDetailItem {
  const _TripDetailItem({
    required this.id,
    required this.dateLabel,
    required this.routeLabel,
    required this.driverName,
    required this.plate,
    required this.pickupPoint,
    required this.seats,
    required this.amount,
    required this.status,
  });

  final String id;
  final String dateLabel;
  final String routeLabel;
  final String driverName;
  final String plate;
  final String pickupPoint;
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

  factory _TripDetailItem.fromMap(Map<String, dynamic> map) {
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
    final createdAt = DateTime.tryParse(
      trip['scheduled_departure_at']?.toString() ?? map['created_at']?.toString() ?? '',
    )?.toLocal();
    final dateLabel = createdAt == null
        ? 'Fecha no disponible'
        : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} '
            '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return _TripDetailItem(
      id: map['id'].toString(),
      dateLabel: dateLabel,
      routeLabel: (routeName != null && routeName.isNotEmpty) ? routeName : '$fromLabel → $toLabel',
      driverName: (profile['name']?.toString().trim().isNotEmpty ?? false)
          ? profile['name'].toString().trim()
          : (fullName.isNotEmpty ? fullName : 'Conductor sin nombre'),
      plate: driver['plate']?.toString() ?? 'Sin placa',
      pickupPoint: map['pickup_point']?.toString().trim().isNotEmpty == true
          ? map['pickup_point'].toString().trim()
          : '-',
      seats: ((map['seats'] as List?) ?? const <dynamic>[])
          .whereType<int>()
          .toList(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? '',
    );
  }
}

