import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../app/router/app_routes.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/viaje_provider.dart';

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

Future<List<LatLng>> _fetchDirections(LatLng origin, LatLng destination) async {
  const apiKey = 'AIzaSyBspcTEh828O90o862FewdtQeCek9MIXOk';
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/directions/json'
    '?origin=${origin.latitude},${origin.longitude}'
    '&destination=${destination.latitude},${destination.longitude}'
    '&key=$apiKey&language=es',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final encoded = data['routes'][0]['overview_polyline']['points'] as String;
        return _decodePolyline(encoded);
      }
    }
  } catch (_) {}
  return [origin, destination];
}

class MapaViajeScreen extends ConsumerStatefulWidget {
  const MapaViajeScreen({super.key});

  @override
  ConsumerState<MapaViajeScreen> createState() => _MapaViajeScreenState();
}

class _MapaViajeScreenState extends ConsumerState<MapaViajeScreen> {
  static const _origin = LatLng(-12.0931, -76.9662);
  static const _destination = LatLng(-11.9333, -76.7000);
  static const _mid = LatLng(-12.0464, -76.9156);

  List<LatLng> _routePoints = const [_origin, _mid, _destination];
  bool _loadingRoute = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _fetchDirections(_origin, _destination).then((points) {
        if (mounted) setState(() { _routePoints = points; _loadingRoute = false; });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = ref.watch(reservaProvider);
    final viaje = ref.watch(viajeProvider);
    ref.listen<ViajeState>(viajeProvider, (previous, next) {
      if (next.finished && previous?.finished != true) {
        context.go(AppRoutes.passengerCalificacion);
      }
    });

    final driver = reserva.conductorSeleccionado;
    if (driver == null || reserva.reservaId == null) {
      return const AppScaffold(
        title: 'Ubicación',
        body: PlaceholderPage(
          title: 'No hay viaje activo',
          subtitle: 'Confirma una reserva para ver el mapa del viaje.',
        ),
      );
    }

    final vehicle = LatLng(viaje.vehiclePosition.lat, viaje.vehiclePosition.lng);
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: AppColors.primaryBlue,
      width: 5,
      points: _routePoints,
    );

    return Scaffold(
      body: Stack(
        children: [
          if (kIsWeb)
            _WebMapFallback(vehicleLabel: '${driver.name} · ${driver.plate}')
          else
            GoogleMap(
              initialCameraPosition: const CameraPosition(target: _mid, zoom: 11),
              polylines: {polyline},
              markers: {
                Marker(
                  markerId: const MarkerId('vehicle'),
                  position: vehicle,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
                const Marker(markerId: MarkerId('pickup'), position: _origin),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          if (_loadingRoute && !kIsWeb)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: SafeArea(
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Ink(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: AppSpacing.shadowBlur,
                        offset: Offset(0, AppSpacing.shadowOffsetY),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.p20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.r16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.82),
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Llegas en ~35 min',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${driver.name} · ${driver.plate}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.energeticOrange,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.r12),
                            ),
                          ),
                          onPressed: () async {
                            final ok = await _confirmDrop(context);
                            if (!context.mounted) return;
                            if (!ok) return;
                            AppSnackbars.success(context, 'Bajada registrada');
                            context.pop();
                          },
                          child: const Text('Bajarme aquí'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDrop(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bajarme aquí'),
          content: const Text('¿Confirmas que bajas aquí?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback({required this.vehicleLabel});

  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fieldFill,
      child: Center(
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_rounded, color: AppColors.primaryBlue, size: 42),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Mapa no disponible en Web',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  vehicleLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}