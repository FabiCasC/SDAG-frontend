import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/app_navigation_back.dart';
import '../../../shared/maps/google_directions_service.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_viaje_provider.dart';

const _driverMapsApiKey = 'AIzaSyBspcTEh828O90o862FewdtQeCek9MIXOk';

class ConductorMapaScreen extends ConsumerStatefulWidget {
  const ConductorMapaScreen({super.key});

  @override
  ConsumerState<ConductorMapaScreen> createState() => _ConductorMapaScreenState();
}

class _ConductorMapaScreenState extends ConsumerState<ConductorMapaScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  LatLng? _driverPosition;
  String? _tripId;
  bool _loading = true;
  String? _errorMessage;
  List<_PickupMarkerData> _pickupMarkers = const <_PickupMarkerData>[];
  List<LatLng> _routePolyline = const <LatLng>[];
  bool _routeLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDriverMap();
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 15),
          (_) => _loadDriverMap(silent: true),
        );
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viaje = ref.watch(conductorViajeProvider);
    final pasajeros = [...viaje.pasajerosViaje]..sort((a, b) => a.asiento.compareTo(b.asiento));

    final markers = <Marker>{
      if (_driverPosition != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      ..._pickupMarkers.map(
        (pickup) => Marker(
          markerId: MarkerId('pickup_${pickup.id}'),
          position: pickup.position,
          infoWindow: InfoWindow(
            title: pickup.title,
            snippet: pickup.subtitle,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          if (kIsWeb)
            const _WebMapFallback()
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _driverPosition ?? const LatLng(-12.0464, -76.9156),
                zoom: 13,
              ),
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitBounds();
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              markers: markers,
              polylines: {
                if (_routePolyline.length >= 2)
                  Polyline(
                    polylineId: const PolylineId('ruta_san_isidro_chosica'),
                    points: _routePolyline,
                    color: const Color(0xFF2563EB),
                    width: 4,
                  ),
              },
            ),
          if (_loading && !kIsWeb)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            child: SafeArea(
              child: InkWell(
                onTap: () => popOrGo(context, AppRoutes.driverHome),
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
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.28,
              minChildSize: 0.18,
              maxChildSize: 0.52,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r16)),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: AppSpacing.shadowBlur,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.sm, AppSpacing.p20, AppSpacing.p20),
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Mapa del viaje',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _tripId == null
                            ? 'No hay un viaje activo en este momento.'
                            : 'Tu GPS se actualiza en tiempo real y se muestran los puntos de recojo de tus pasajeros.',
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
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Paradas',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (pasajeros.isEmpty)
                        Text(
                          'No hay pasajeros activos para este viaje.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        )
                      else
                        ...pasajeros.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(AppRadius.r16),
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.infoSurface,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      '${p.asiento}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.nombre,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          p.puntoRecojo,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: 120,
            child: Column(
              children: [
                _FabCircle(
                  icon: Icons.my_location_rounded,
                  bg: const Color(0xFF2563EB),
                  onTap: _center,
                ),
                const SizedBox(height: AppSpacing.sm),
                _FabCircle(
                  icon: Icons.qr_code_scanner_rounded,
                  bg: const Color(0xFFF97316),
                  onTap: () => context.push(AppRoutes.driverQrScanner),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDriverMap({bool silent = false}) async {
    if (!mounted || kIsWeb) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      await _ensureDriverLocationPermission();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No hay sesión activa del conductor.');
      }

      final position = await Geolocator.getCurrentPosition();
      final driverPosition = LatLng(position.latitude, position.longitude);

      final driverRow = await Supabase.instance.client
          .from('drivers')
          .select('id, capacity')
          .eq('profile_id', user.id)
          .single();
      final driverId = driverRow['id']?.toString();
      if (driverId == null || driverId.isEmpty) {
        throw Exception('No se encontró el conductor autenticado.');
      }

      final tripRow = await Supabase.instance.client
          .from('trips')
          .select('id')
          .eq('driver_id', driverId)
          .neq('status', 'completado')
          .neq('status', 'cancelado')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final tripId = tripRow?['id']?.toString();

      await Supabase.instance.client.from('driver_locations').upsert({
        'driver_id': driverId,
        'trip_id': tripId,
        'lat': driverPosition.latitude,
        'lng': driverPosition.longitude,
        'occupied_seats': ref.read(conductorViajeProvider).asientosOcupados.length,
        'capacity': (driverRow['capacity'] as int?) ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final pickups = tripId == null ? const <_PickupMarkerData>[] : await _loadPickupMarkers(tripId);

      if (!_routeLoaded) {
        _routePolyline = await fetchRoutePolyline(
          origin: driverPosition,
          destination: const LatLng(-11.9375, -76.6934),
        );
        _routeLoaded = true;
      }

      if (!mounted) return;
      setState(() {
        _tripId = tripId;
        _driverPosition = driverPosition;
        _pickupMarkers = pickups;
        _loading = false;
        _errorMessage = null;
      });
      _fitBounds();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<List<_PickupMarkerData>> _loadPickupMarkers(String tripId) async {
    final reservations = await Supabase.instance.client
        .from('reservations')
        .select('''
          id,
          pickup_point,
          pickup_point_id,
          seats,
          profiles:passenger_profile_id(name, first_name, last_name),
          pickup_points(address, lat, lng)
        ''')
        .eq('trip_id', tripId)
        .eq('status', 'activa');

    final markers = <_PickupMarkerData>[];
    for (final raw in (reservations as List).cast<Map<String, dynamic>>()) {
      final row = Map<String, dynamic>.from(raw);
      final profile = row['profiles'] is Map ? Map<String, dynamic>.from(row['profiles'] as Map) : <String, dynamic>{};
      final pickupPoint = row['pickup_points'] is Map ? Map<String, dynamic>.from(row['pickup_points'] as Map) : <String, dynamic>{};
      final lat = (pickupPoint['lat'] as num?)?.toDouble();
      final lng = (pickupPoint['lng'] as num?)?.toDouble();
      LatLng? position;

      if (lat != null && lng != null) {
        position = LatLng(lat, lng);
      } else {
        final address = row['pickup_point']?.toString().trim();
        if (address != null && address.isNotEmpty && address != '—') {
          position = await _geocodeAddress(address);
        }
      }

      if (position == null) continue;

      final seats = _parseSeats(row['seats']);
      final passengerName = _passengerNameFromProfile(profile);

      markers.add(
        _PickupMarkerData(
          id: row['id'].toString(),
          position: position,
          title: passengerName,
          subtitle: '${row['pickup_point'] ?? pickupPoint['address'] ?? 'Punto de recojo'} · ${seats.map((s) => '#$s').join(', ')}',
        ),
      );
    }

    return markers;
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=${Uri.encodeComponent('$address, Lima, Peru')}'
      '&key=$_driverMapsApiKey&language=es',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json['status'] != 'OK') return null;
      final location = json['results'][0]['geometry']['location'];
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fitBounds() async {
    final controller = _mapController;
    final driver = _driverPosition;
    if (controller == null || driver == null) return;

    final points = <LatLng>[
      driver,
      ..._pickupMarkers.map((e) => e.position),
      ..._routePolyline,
    ];
    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: driver, zoom: 14),
      ));
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  void _center() {
    if (_driverPosition == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _driverPosition!, zoom: 14),
      ),
    );
  }
}

class _PickupMarkerData {
  const _PickupMarkerData({
    required this.id,
    required this.position,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final LatLng position;
  final String title;
  final String subtitle;
}

class _FabCircle extends StatelessWidget {
  const _FabCircle({
    required this.icon,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Ink(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppSpacing.shadowBlur,
              offset: Offset(0, AppSpacing.shadowOffsetY),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.white),
      ),
    );
  }
}

class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback();

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<int> _parseSeats(dynamic rawSeats) {
  if (rawSeats is! List) return const [];
  final unique = <int>{};
  for (final seat in rawSeats) {
    final parsed = seat is int ? seat : int.tryParse(seat.toString());
    if (parsed != null) unique.add(parsed);
  }
  return unique.toList()..sort();
}

String _passengerNameFromProfile(Map<String, dynamic> profile) {
  final name = profile['name']?.toString().trim();
  if (name != null && name.isNotEmpty) return name;
  final first = profile['first_name']?.toString().trim() ?? '';
  final last = profile['last_name']?.toString().trim() ?? '';
  final full = '$first $last'.trim();
  return full.isNotEmpty ? full : 'Pasajero';
}

Future<void> _ensureDriverLocationPermission() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) {
    throw Exception('Activa la ubicación del dispositivo para usar el mapa.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw Exception('La app no tiene permiso para acceder a tu ubicación.');
  }
}
