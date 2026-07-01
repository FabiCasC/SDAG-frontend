import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../../reserva/providers/reserva_provider.dart';
import '../../../data/models/route_polyline_model.dart';
import '../../../shared/widgets/mapa_ruta_widget.dart';
import '../../../shared/maps/waze_service.dart';
class ConductorDetalleScreen extends ConsumerWidget {
  const ConductorDetalleScreen({
    required this.driverId,
    required this.tripId,
    super.key,
  });

  final String? driverId;
  final String? tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = _DriverTripLookup(driverId: driverId, tripId: tripId);
    final detailAsync = ref.watch(driverTripDetailProvider(lookup));

    return detailAsync.when(
      loading: () => const AppScaffold(
        title: 'Conductor',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppScaffold(
        title: 'Conductor',
        body: PlaceholderPage(
          title: 'No se pudo cargar el conductor',
          subtitle: error.toString(),
        ),
      ),
      data: (driver) {
        final theme = Theme.of(context);
        final initials = _initials(driver.name);

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                title: const Text('Conductor'),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: AppColors.primaryBlue),
                      Container(color: AppColors.primaryTint18),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.p20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.white,
                                child: Text(
                                  initials,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver.name,
                                      style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.white),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          5,
                                          (i) => Icon(
                                            Icons.star_rounded,
                                            size: 18,
                                            color: i < driver.rating.round()
                                                ? AppColors.ratingStar
                                                : AppColors.primaryTint12,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            '${driver.rating.toStringAsFixed(1)} · ${driver.ratingCount} valoraciones',
                                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                icon: Icons.confirmation_number_rounded,
                                label: 'Placa',
                                value: driver.plate,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _InfoRow(
                                icon: Icons.directions_bus_rounded,
                                label: 'Vehiculo',
                                value: driver.vehicleType,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _InfoRow(
                                icon: Icons.event_seat_rounded,
                                label: 'Capacidad',
                                value: '${driver.totalSeats} asientos',
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _InfoRow(
                                icon: Icons.alt_route_rounded,
                                label: 'Ruta',
                                value: driver.routeLabel,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _InfoRow(
                                icon: Icons.info_outline_rounded,
                                label: 'Estado',
                                value: driver.status.isEmpty ? 'Sin estado' : driver.status,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (driver.routePolyline != null)
                        SizedBox(
                          height: 190,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.r16),
                            child: MapaRutaWidget(routePolyline: driver.routePolyline!),
                          ),
                        )
                      else
                        _RoutePreview(routeLabel: driver.routeLabel),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text('Ver ruta en Waze'),
                        onPressed: () async {
                          final poly = driver.routePolyline;
                          if (poly == null || poly.points.length < 2) {
                            AppSnackbars.warning(context, mensajeWazeNoDisponible());
                            return;
                          }
                          final from = poly.points.first;
                          final to = poly.points.last;
                          if (!wazeDisponible(lat: to.lat, lng: to.lng)) {
                            AppSnackbars.warning(context, mensajeWazeNoDisponible());
                            return;
                          }
                          final uri = buildWazeRouteUri(
                            fromLat: from.lat,
                            fromLng: from.lng,
                            toLat: to.lat,
                            toLng: to.lng,
                          );
                          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                          if (!ok && context.mounted) {
                            AppSnackbars.warning(context, mensajeWazeNoDisponible());
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.energeticOrange,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                          ),
                          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          ref.read(reservaProvider.notifier).startWithDriver(driver);
                          context.push(
                            '${AppRoutes.passengerSeatMap}?id=${driver.driverId}&tripId=${driver.tripId}',
                          );
                        },
                        child: const Text('Seleccionar asientos'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}

final driverTripDetailProvider =
    FutureProvider.autoDispose.family<ReservaDriverInfo, _DriverTripLookup>((ref, lookup) async {
  final client = Supabase.instance.client;
  dynamic response;

  if (lookup.tripId != null && lookup.tripId!.trim().isNotEmpty) {
    response = await client
        .from('trips')
        .select('''
          id,
          status,
          drivers (
            id,
            plate,
            vehicle_type,
            capacity,
            estado,
            rating_avg,
            rating_count,
            profiles (
              name,
              first_name,
              last_name
            )
          ),
          vehicles(id, total_seats),
          routes (
            name,
            from_label,
            to_label,
            polyline
          )
        ''')
        .eq('id', lookup.tripId!)
        .eq('status', 'esperando')
        .maybeSingle();
  } else if (lookup.driverId != null && lookup.driverId!.trim().isNotEmpty) {
    response = await client
        .from('trips')
        .select('''
          id,
          status,
          drivers!inner (
            id,
            plate,
            vehicle_type,
            capacity,
            estado,
            rating_avg,
            rating_count,
            profiles (
              name,
              first_name,
              last_name
            )
          ),
          vehicles(id, total_seats),
          routes (
            name,
            from_label,
            to_label,
            polyline
          )
        ''')
        .eq('driver_id', lookup.driverId!)
        .eq('status', 'esperando')
        .order('scheduled_departure_at', ascending: true)
        .limit(1)
        .maybeSingle();
  } else {
    throw Exception('Conductor no encontrado');
  }

  if (response == null) {
    throw Exception('No hay viaje en espera para este conductor o el viaje ya no está disponible.');
  }

  final row = Map<String, dynamic>.from(response as Map);
  final driver = row['drivers'];
  final route = row['routes'];

  if (driver is! Map || route is! Map) {
    throw Exception('Faltan datos del conductor o la ruta');
  }

  final driverMap = Map<String, dynamic>.from(driver);
  final routeMap = Map<String, dynamic>.from(route);
  final profile = driverMap['profiles'] is Map ? Map<String, dynamic>.from(driverMap['profiles'] as Map) : null;
  final firstName = profile?['first_name']?.toString().trim() ?? '';
  final lastName = profile?['last_name']?.toString().trim() ?? '';
  final fullName = '$firstName $lastName'.trim();
  final routeName = routeMap['name']?.toString().trim();
  final routeFrom = routeMap['from_label']?.toString().trim() ?? '';
  final routeTo = routeMap['to_label']?.toString().trim() ?? '';

  var totalSeats = (driverMap['capacity'] as num?)?.toInt() ?? 0;
  final vehicles = row['vehicles'];
  if (vehicles is Map) {
    final v = Map<String, dynamic>.from(vehicles);
    final ts = (v['total_seats'] as num?)?.toInt();
    if (ts != null && ts > 0) totalSeats = ts;
  }

  final polylineJson = routeMap['polyline'];
  RoutePolyline? routePolyline;
  if (polylineJson != null) {
    routePolyline = RoutePolyline.fromJson(
      Map<String, dynamic>.from(polylineJson as Map),
    );
  }
  return ReservaDriverInfo(
    tripId: row['id'].toString(),
    driverId: driverMap['id'].toString(),
    name: (profile?['name']?.toString().trim().isNotEmpty ?? false)
        ? profile!['name'].toString().trim()
        : (fullName.isNotEmpty ? fullName : 'Conductor sin nombre'),
    plate: driverMap['plate']?.toString() ?? 'Sin placa',
    vehicleType: driverMap['vehicle_type']?.toString() ?? 'Vehiculo',
    totalSeats: totalSeats,
    routeLabel: (routeName != null && routeName.isNotEmpty) ? routeName : '$routeFrom → $routeTo',
    rating: (driverMap['rating_avg'] as num?)?.toDouble() ?? 0,
    ratingCount: (driverMap['rating_count'] as num?)?.toInt() ?? 0,
    status: driverMap['estado']?.toString() ?? (row['status']?.toString() ?? ''),
    routePolyline: routePolyline,
  );
});

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.routeLabel});

  final String routeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alt_route_rounded, size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    routeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final padding = size.shortestSide * 0.12;
    final p1 = Offset(padding, size.height * 0.7);
    final p2 = Offset(size.width * 0.5, size.height * 0.42);
    final p3 = Offset(size.width - padding, size.height * 0.3);

    final linePaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(p2.dx, p2.dy, p3.dx, p3.dy);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primaryBlue;
    canvas.drawCircle(p1, 6, dotPaint);
    canvas.drawCircle(p3, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DriverTripLookup {
  const _DriverTripLookup({
    required this.driverId,
    required this.tripId,
  });

  final String? driverId;
  final String? tripId;

  @override
  bool operator ==(Object other) {
    return other is _DriverTripLookup &&
        other.driverId == driverId &&
        other.tripId == tripId;
  }

  @override
  int get hashCode => Object.hash(driverId, tripId);
}
