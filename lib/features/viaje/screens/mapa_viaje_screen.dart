import 'dart:convert';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/viaje_provider.dart';

const _mapsApiKey = 'AIzaSyBspcTEh828O90o862FewdtQeCek9MIXOk';

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
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/directions/json'
    '?origin=${origin.latitude},${origin.longitude}'
    '&destination=${destination.latitude},${destination.longitude}'
    '&key=$_mapsApiKey&language=es',
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
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  List<LatLng> _routePoints = const <LatLng>[];
  LatLng? _passengerPosition;
  LatLng? _driverPosition;
  int? _driverEta;
  String? _errorMessage;
  bool _loadingRoute = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
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

    if (!kIsWeb && !_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMapData(driver.driverId);
        _refreshTimer?.cancel();
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 15),
          (_) => _loadMapData(driver.driverId, silent: true),
        );
      });
    }

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
              initialCameraPosition: CameraPosition(
                target: _cameraTarget(),
                zoom: 13,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _fitBounds();
              },
              polylines: _routePoints.length >= 2 ? {polyline} : const <Polyline>{},
              markers: {
                if (_passengerPosition != null)
                  Marker(
                    markerId: const MarkerId('passenger'),
                    position: _passengerPosition!,
                    infoWindow: const InfoWindow(title: 'Tu ubicación'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
                if (_driverPosition != null)
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: _driverPosition!,
                    infoWindow: InfoWindow(title: driver.name, snippet: driver.plate),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
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
                          'Conductor en camino',
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
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'ETA estimado: ${_driverEta ?? viaje.etaMinutes} min',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
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

  Future<void> _loadMapData(String driverId, {bool silent = false}) async {
    if (!mounted || kIsWeb) return;
    if (!silent) {
      setState(() {
        _loadingRoute = true;
        _errorMessage = null;
      });
    }

    try {
      await _ensureLocationPermission();
      final position = await Geolocator.getCurrentPosition();
      final passengerLatLng = LatLng(position.latitude, position.longitude);

      final driverLocation = await Supabase.instance.client
          .from('driver_locations')
          .select('lat, lng, eta_minutes')
          .eq('driver_id', driverId)
          .single();

      final driverLat = (driverLocation['lat'] as num?)?.toDouble();
      final driverLng = (driverLocation['lng'] as num?)?.toDouble();
      if (driverLat == null || driverLng == null) {
        throw Exception('La ubicación del conductor aún no está disponible.');
      }

      final driverLatLng = LatLng(driverLat, driverLng);
      final directions = await _fetchDirections(passengerLatLng, driverLatLng);

      if (!mounted) return;
      setState(() {
        _passengerPosition = passengerLatLng;
        _driverPosition = driverLatLng;
        _driverEta = driverLocation['eta_minutes'] as int?;
        _routePoints = directions;
        _errorMessage = null;
        _loadingRoute = false;
      });
      _fitBounds();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loadingRoute = false;
      });
    }
  }

  LatLng _cameraTarget() {
    if (_passengerPosition != null && _driverPosition != null) {
      return LatLng(
        (_passengerPosition!.latitude + _driverPosition!.latitude) / 2,
        (_passengerPosition!.longitude + _driverPosition!.longitude) / 2,
      );
    }
    return _passengerPosition ?? _driverPosition ?? const LatLng(-12.0464, -76.9156);
  }

  Future<void> _fitBounds() async {
    final controller = _mapController;
    final passenger = _passengerPosition;
    final driver = _driverPosition;
    if (controller == null || passenger == null || driver == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        passenger.latitude < driver.latitude ? passenger.latitude : driver.latitude,
        passenger.longitude < driver.longitude ? passenger.longitude : driver.longitude,
      ),
      northeast: LatLng(
        passenger.latitude > driver.latitude ? passenger.latitude : driver.latitude,
        passenger.longitude > driver.longitude ? passenger.longitude : driver.longitude,
      ),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }
}

Future<void> _ensureLocationPermission() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) {
    throw Exception('Activa la ubicación del dispositivo para ver el mapa.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw Exception('La app no tiene permiso para acceder a tu ubicación.');
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
