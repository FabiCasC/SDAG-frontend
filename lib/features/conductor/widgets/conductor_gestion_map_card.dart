import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/maps/google_directions_service.dart';
import '../../../shared/maps/google_places_service.dart';

const _chosicaDestino = LatLng(-11.9375, -76.6934);
const _limaDefault = LatLng(-12.1092, -77.0365);

class ConductorGestionMapCard extends StatefulWidget {
  const ConductorGestionMapCard({required this.tripId, super.key});

  final String tripId;

  @override
  State<ConductorGestionMapCard> createState() => _ConductorGestionMapCardState();
}

class _ConductorGestionMapCardState extends State<ConductorGestionMapCard> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<LatLng> _polylinePoints = const [];
  bool _loading = true;
  String? _error;
  bool _mapInitialized = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _inicializarMapa(GoogleMapController controller) async {
    if (!mounted || kIsWeb || _mapInitialized) return;
    _mapInitialized = true;
    _mapController = controller;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _ensureLocationPermission();
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final conductorPos = LatLng(position.latitude, position.longitude);

      final manifest = await Supabase.instance.client
          .from('manifests')
          .select('id')
          .eq('trip_id', widget.tripId)
          .maybeSingle();

      final pasajeros = manifest == null
          ? <Map<String, dynamic>>[]
          : ((await Supabase.instance.client
                  .from('manifest_entries')
                  .select('id, first_name, last_name, pickup_text')
                  .eq('manifest_id', manifest['id'])
                  .order('seat_number')) as List)
              .cast<Map<String, dynamic>>();

      final markers = <Marker>{
        Marker(
          markerId: const MarkerId('conductor'),
          position: conductorPos,
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };

      for (final pasajero in pasajeros) {
        final pickup = pasajero['pickup_text']?.toString().trim() ?? '';
        if (pickup.isEmpty) continue;

        try {
          final coords = await GooglePlacesService.geocodeAddress(pickup);
          if (coords == null) continue;

          final first = pasajero['first_name']?.toString().trim() ?? '';
          final last = pasajero['last_name']?.toString().trim() ?? '';
          final nombre = '$first $last'.trim();

          markers.add(
            Marker(
              markerId: MarkerId('pickup_${pasajero['id']}'),
              position: coords,
              infoWindow: InfoWindow(
                title: nombre.isEmpty ? 'Pasajero' : nombre,
                snippet: pickup,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
          );
        } catch (_) {
          continue;
        }
      }

      final polyline = await fetchRoutePolyline(
        origin: conductorPos,
        destination: _chosicaDestino,
      );

      if (!mounted) return;
      setState(() {
        _markers = markers;
        _polylinePoints = polyline;
        _loading = false;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(conductorPos, 13),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('Mapa no disponible en Web'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _inicializarMapa,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              initialCameraPosition: const CameraPosition(
                target: _limaDefault,
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylinePoints.isNotEmpty
                  ? {
                      Polyline(
                        polylineId: const PolylineId('ruta'),
                        points: _polylinePoints,
                        color: Colors.blue,
                        width: 4,
                      ),
                    }
                  : const {},
            ),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x88FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (_error != null)
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
