import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../../reserva/providers/reserva_provider.dart';

class ConductorDetalleScreen extends ConsumerWidget {
  const ConductorDetalleScreen({required this.driverId, super.key});

  final String? driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final driver = MockData.drivers.where((d) => d.id == driverId).cast<MockDriver?>().firstOrNull;

    if (driver == null) {
      return const AppScaffold(
        title: 'Conductor',
        body: PlaceholderPage(
          title: 'Conductor no encontrado',
          subtitle: 'Vuelve a la búsqueda para seleccionar otro conductor.',
        ),
      );
    }

    final initials = _initials(driver.name);
    final map = _StaticRouteMap(routeLabel: driver.routeLabel);

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
                                    Text(
                                      '${driver.rating.toStringAsFixed(1)} · ${driver.ratingCount} valoraciones',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.white),
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
                            label: 'Vehículo',
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    child: SizedBox(height: 190, child: map),
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
                      context.push('${AppRoutes.passengerSeatMap}?id=${driver.id}');
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
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}

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

class _StaticRouteMap extends StatefulWidget {
  const _StaticRouteMap({required this.routeLabel});

  final String routeLabel;

  @override
  State<_StaticRouteMap> createState() => _StaticRouteMapState();
}

class _StaticRouteMapState extends State<_StaticRouteMap> {
  static const _apiKey = 'AIzaSyBspcTEh828O90o862FewdtQeCek9MIXOk';
  static const _origin = LatLng(MockData.sanIsidroLat, MockData.sanIsidroLng);
  static const _destination = LatLng(MockData.chosicaLat, MockData.chosicaLng);
  static const _mid = LatLng(MockData.midLat, MockData.midLng);

  List<LatLng> _routePoints = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_origin.latitude},${_origin.longitude}'
        '&destination=${_destination.latitude},${_destination.longitude}'
        '&key=$_apiKey'
        '&language=es',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final encoded = data['routes'][0]['overview_polyline']['points'] as String;
          setState(() {
            _routePoints = _decodePolyline(encoded);
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    // Fallback a línea recta si falla la API
    setState(() {
      _routePoints = const [_origin, _mid, _destination];
      _loading = false;
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _WebStaticMap(routeLabel: widget.routeLabel);

    final polylinePoints = _routePoints.isEmpty ? const [_origin, _mid, _destination] : _routePoints;
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: AppColors.primaryBlue,
      width: 5,
      points: polylinePoints,
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: _mid, zoom: 10.8),
          polylines: {polyline},
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: false,
          liteModeEnabled: false,
          markers: {
            const Marker(markerId: MarkerId('si'), position: _origin),
            const Marker(markerId: MarkerId('ch'), position: _destination),
          },
        ),
        if (_loading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
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
                  widget.routeLabel,
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
    );
  }
}

class _WebStaticMap extends StatelessWidget {
  const _WebStaticMap({required this.routeLabel});

  final String routeLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: CustomPaint(
            painter: _WebRoutePainter(),
            child: const SizedBox.expand(),
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
    );
  }
}

class _WebRoutePainter extends CustomPainter {
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}