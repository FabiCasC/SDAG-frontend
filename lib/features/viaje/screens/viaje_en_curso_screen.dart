import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/maps/google_directions_service.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class ViajeEnCursoScreen extends ConsumerStatefulWidget {
  const ViajeEnCursoScreen({super.key});

  @override
  ConsumerState<ViajeEnCursoScreen> createState() => _ViajeEnCursoScreenState();
}

class _ViajeEnCursoScreenState extends ConsumerState<ViajeEnCursoScreen> {
  GoogleMapController? _mapController;
  List<LatLng> _routePoints = const [];
  bool _loadingRoute = true;
  String? _driverName;
  String? _routeLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final reservaId = GoRouterState.of(context).uri.queryParameters['reservaId']?.trim();
    final reserva = ref.read(reservaProvider);
    var driverName = reserva.conductorSeleccionado?.name;
    var routeLabel = reserva.conductorSeleccionado?.routeLabel ?? 'San Isidro → Chosica';

    if (reservaId != null && reservaId.isNotEmpty) {
      try {
        final row = await Supabase.instance.client
            .from('reservations')
            .select('trip_id, trips(drivers(profiles(name, first_name, last_name)), routes(from_label, to_label, name))')
            .eq('id', reservaId)
            .maybeSingle();
        if (row != null) {
          final trip = row['trips'] is Map ? Map<String, dynamic>.from(row['trips'] as Map) : null;
          if (trip != null) {
            final route = trip['routes'] is Map ? Map<String, dynamic>.from(trip['routes'] as Map) : null;
            final driver = trip['drivers'] is Map ? Map<String, dynamic>.from(trip['drivers'] as Map) : null;
            final profile = driver?['profiles'] is Map
                ? Map<String, dynamic>.from(driver!['profiles'] as Map)
                : null;
            driverName = profile?['name']?.toString().trim();
            if (driverName == null || driverName.isEmpty) {
              final first = profile?['first_name']?.toString().trim() ?? '';
              final last = profile?['last_name']?.toString().trim() ?? '';
              final full = '$first $last'.trim();
              if (full.isNotEmpty) driverName = full;
            }
            final from = route?['from_label']?.toString().trim() ?? 'San Isidro';
            final to = route?['to_label']?.toString().trim() ?? 'Chosica';
            final name = route?['name']?.toString().trim();
            routeLabel = (name != null && name.isNotEmpty) ? name : '$from → $to';
          }
        }
      } catch (_) {}
    }

    final points = await fetchRoutePolyline();
    if (!mounted) return;
    setState(() {
      _routePoints = points;
      _driverName = driverName ?? 'Conductor';
      _routeLabel = routeLabel;
      _loadingRoute = false;
    });
    _fitCamera();
  }

  Future<void> _fitCamera() async {
    if (_routePoints.length < 2 || _mapController == null) return;
    var minLat = _routePoints.first.latitude;
    var maxLat = _routePoints.first.latitude;
    var minLng = _routePoints.first.longitude;
    var maxLng = _routePoints.first.longitude;
    for (final p in _routePoints) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: AppColors.primaryBlue,
      width: 5,
      points: _routePoints,
    );

    return AppScaffold(
      title: 'Viaje en curso',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 88),
          const SizedBox(height: AppSpacing.md),
          Text(
            '¡Ya abordaste!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Conductor: ${_driverName ?? '—'}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ruta: ${_routeLabel ?? 'San Isidro → Chosica'}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _loadingRoute
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _routePoints.isNotEmpty ? _routePoints.first : const LatLng(-12.0992, -77.0342),
                        zoom: 11,
                      ),
                      scrollGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      polylines: _routePoints.length >= 2 ? {polyline} : const {},
                      markers: {
                        if (_routePoints.isNotEmpty)
                          Marker(
                            markerId: const MarkerId('origin'),
                            position: _routePoints.first,
                            infoWindow: const InfoWindow(title: 'Origen'),
                          ),
                        if (_routePoints.length > 1)
                          Marker(
                            markerId: const MarkerId('destination'),
                            position: _routePoints.last,
                            infoWindow: const InfoWindow(title: 'Destino'),
                          ),
                      },
                      onMapCreated: (c) {
                        _mapController = c;
                        _fitCamera();
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Ver en mapa en tiempo real',
            onPressed: () => context.push(AppRoutes.passengerMapaViaje),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
