import 'dart:async';
import 'dart:convert';
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
import '../../../core/config/google_maps_config.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_navigation_back.dart';
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
    shift = 0;
    result = 0;
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
  final key = googleMapsRestApiKey();
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/directions/json'
    '?origin=${origin.latitude},${origin.longitude}'
    '&destination=${destination.latitude},${destination.longitude}'
    '&key=$key&language=es',
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
  List<LatLng> _routePoints = const <LatLng>[];
  LatLng? _pasajeroPos;
  LatLng? _conductorPos;
  bool _conductorDisponible = false;
  int? _etaMinutos;
  bool _loadingRoute = true;
  bool _initialized = false;
  bool _routeFetched = false;
  bool _yaAbordo = false;

  StreamSubscription<List<Map<String, dynamic>>>? _conductorSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _boardingSubscription;
  LatLng? _lastConductorPosEta;

  @override
  void dispose() {
    _conductorSubscription?.cancel();
    _boardingSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> get _markers => {
        if (_conductorPos != null)
          Marker(
            markerId: const MarkerId('conductor'),
            position: _conductorPos!,
            infoWindow: const InfoWindow(title: 'Conductor'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        if (_pasajeroPos != null)
          Marker(
            markerId: const MarkerId('pasajero'),
            position: _pasajeroPos!,
            infoWindow: const InfoWindow(title: 'Tu ubicacion'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final reserva = ref.watch(reservaProvider);
    ref.listen<ViajeState>(viajeProvider, (previous, next) {
      if (next.finished && previous?.finished != true) {
        context.go(AppRoutes.passengerCalificacion);
      }
    });

    final driver = reserva.conductorSeleccionado;
    final reservaId = reserva.reservaId;
    if (driver == null || reservaId == null) {
      return const AppScaffold(
        title: 'Ubicacion',
        body: PlaceholderPage(
          title: 'No hay viaje activo',
          subtitle: 'Confirma una reserva para ver el mapa del viaje.',
        ),
      );
    }

    if (!kIsWeb && !_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_inicializarMapa(reservaId));
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
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitBounds();
              },
              polylines: _routePoints.length >= 2 ? {polyline} : const <Polyline>{},
              markers: _markers,
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
                onTap: () => popOrGo(context, AppRoutes.passengerReservaActiva),
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
                        const SizedBox(height: AppSpacing.sm),
                        if (!_conductorDisponible)
                          Text(
                            'Ubicacion del conductor aproximada — GPS no activo',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                          )
                        else if (_etaMinutos != null)
                          Text(
                            'El conductor llegara en ≈ $_etaMinutos min',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          )
                        else
                          Text(
                            'Calculando tiempo de llegada...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        if (_yaAbordo) ...[
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            icon: const Icon(Icons.exit_to_app_rounded),
                            label: const Text('Bajarme aqui'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.r12),
                              ),
                            ),
                            onPressed: _bajarmAqui,
                          ),
                        ],
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

  Future<void> _inicializarMapa(String reservaId) async {
    if (!mounted || kIsWeb) return;
    setState(() {
      _loadingRoute = true;
    });

    try {
      await _ensureLocationPermission();
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _pasajeroPos = LatLng(position.latitude, position.longitude));

      await Future.wait([
        _cargarUbicacionConductor(reservaId),
        _verificarEstadoAbordaje(reservaId),
      ]);

      if (_conductorPos != null && _pasajeroPos != null && !_routeFetched) {
        _routePoints = await _fetchDirections(_pasajeroPos!, _conductorPos!);
        _routeFetched = true;
      }

      await _calcularEtaInicial();

      if (!mounted) return;
      setState(() => _loadingRoute = false);
      _fitBounds();
    } catch (e) {
      debugPrint('[Mapa] Error inicializando: $e');
      if (!mounted) return;
      setState(() => _loadingRoute = false);
    }
  }

  Future<void> _cargarUbicacionConductor(String reservaId) async {
    try {
      final reserva = await Supabase.instance.client
          .from('reservations')
          .select('trip_id, trips(driver_id)')
          .eq('id', reservaId)
          .single();

      final trips = reserva['trips'];
      final tripMap = trips is Map ? Map<String, dynamic>.from(trips) : null;
      final driverId = tripMap?['driver_id']?.toString();
      if (driverId == null || driverId.isEmpty) return;

      final loc = await Supabase.instance.client
          .from('driver_locations')
          .select('lat, lng, updated_at')
          .eq('driver_id', driverId)
          .maybeSingle();

      if (loc == null) {
        if (!mounted) return;
        setState(() {
          _conductorPos = const LatLng(-12.1092, -77.0365);
          _conductorDisponible = false;
        });
      } else {
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) {
          if (!mounted) return;
          setState(() {
            _conductorPos = const LatLng(-12.1092, -77.0365);
            _conductorDisponible = false;
          });
        } else if (mounted) {
          setState(() {
            _conductorPos = LatLng(lat, lng);
            _conductorDisponible = true;
          });
        }
      }

      _conductorSubscription?.cancel();
      _conductorSubscription = Supabase.instance.client
          .from('driver_locations')
          .stream(primaryKey: ['driver_id'])
          .eq('driver_id', driverId)
          .listen((data) {
        if (data.isEmpty || !mounted) return;
        final lat = (data[0]['lat'] as num?)?.toDouble();
        final lng = (data[0]['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return;
        setState(() {
          _conductorPos = LatLng(lat, lng);
          _conductorDisponible = true;
        });
        unawaited(_actualizarEtaSiMovio());
      });
    } catch (e) {
      debugPrint('[Mapa] Error cargando ubicacion conductor: $e');
      if (!mounted) return;
      setState(() {
        _conductorPos = const LatLng(-12.1092, -77.0365);
        _conductorDisponible = false;
      });
    }
  }

  Future<void> _verificarEstadoAbordaje(String reservaId) async {
    try {
      final entries = await Supabase.instance.client
          .from('manifest_entries')
          .select('boarding_status')
          .eq('reservation_id', reservaId);

      final rows = (entries as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _yaAbordo = rows.any((e) => e['boarding_status']?.toString() == 'abordo');
        });
      }

      _boardingSubscription?.cancel();
      _boardingSubscription = Supabase.instance.client
          .from('manifest_entries')
          .stream(primaryKey: ['id'])
          .eq('reservation_id', reservaId)
          .listen((data) {
        if (data.isEmpty || !mounted) return;
        setState(() {
          _yaAbordo = data.any((e) => e['boarding_status']?.toString() == 'abordo');
        });
      });
    } catch (e) {
      debugPrint('[Mapa] Error verificando abordaje: $e');
    }
  }

  Future<void> _calcularEtaInicial() async {
    if (_conductorPos == null || _pasajeroPos == null) return;

    try {
      final key = googleMapsRestApiKey();
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=${_conductorPos!.latitude},${_conductorPos!.longitude}'
        '&destinations=${_pasajeroPos!.latitude},${_pasajeroPos!.longitude}'
        '&departure_time=now'
        '&key=$key',
      );
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('[ETA] status=${data['status']}');

      final rows = data['rows'] as List?;
      final elements = rows != null && rows.isNotEmpty ? rows[0]['elements'] as List? : null;
      final element = elements != null && elements.isNotEmpty
          ? elements[0] as Map<String, dynamic>?
          : null;
      if (element == null || element['status'] != 'OK') return;

      final duracion = element['duration_in_traffic']?['value'] ?? element['duration']?['value'];
      if (duracion == null) return;

      if (mounted) {
        setState(() => _etaMinutos = ((duracion as num) / 60).round());
      }
    } catch (e) {
      debugPrint('[ETA] Error: $e');
    }
  }

  Future<void> _actualizarEtaSiMovio() async {
    if (_conductorPos == null) return;
    if (_lastConductorPosEta != null) {
      final distancia = Geolocator.distanceBetween(
        _lastConductorPosEta!.latitude,
        _lastConductorPosEta!.longitude,
        _conductorPos!.latitude,
        _conductorPos!.longitude,
      );
      if (distancia < 300) return;
    }
    _lastConductorPosEta = _conductorPos;
    await _calcularEtaInicial();
  }

  Future<void> _bajarmAqui() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bajada anticipada'),
        content: const Text(
          'Te estas bajando antes de tiempo.\n\nMuchas gracias por viajar con nosotros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar bajada'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final reserva = ref.read(reservaProvider);
    final reservaId = reserva.reservaId;

    if (reservaId == null || reservaId.isEmpty) {
      if (!mounted) return;
      AppSnackbars.error(context, 'No se encontro la reserva activa');
      return;
    }

    try {
      await Supabase.instance.client
          .from('reservations')
          .update({'status': 'completada'})
          .eq('id', reservaId);

      await Supabase.instance.client
          .from('profiles')
          .update({'has_active_reservation': false})
          .eq('id', userId);

      final manifestEntries = await Supabase.instance.client
          .from('manifest_entries')
          .select('id, boarding_status')
          .eq('reservation_id', reservaId);

      for (final raw in (manifestEntries as List).cast<Map<String, dynamic>>()) {
        final boarding = raw['boarding_status']?.toString();
        if (boarding == 'abordo') continue;
        await Supabase.instance.client
            .from('manifest_entries')
            .update({'boarding_status': 'no_abordo'})
            .eq('id', raw['id']);
      }

      ref.read(reservaProvider.notifier).reset();
      ref.invalidate(viajeProvider);

      if (!mounted) return;
      context.go(AppRoutes.passengerHome);
    } catch (_) {
      if (!mounted) return;
      AppSnackbars.error(context, 'No se pudo completar el viaje');
    }
  }

  LatLng _cameraTarget() {
    if (_pasajeroPos != null && _conductorPos != null) {
      return LatLng(
        (_pasajeroPos!.latitude + _conductorPos!.latitude) / 2,
        (_pasajeroPos!.longitude + _conductorPos!.longitude) / 2,
      );
    }
    return _pasajeroPos ?? _conductorPos ?? const LatLng(-12.0464, -76.9156);
  }

  Future<void> _fitBounds() async {
    final controller = _mapController;
    final passenger = _pasajeroPos;
    final driver = _conductorPos;
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
    throw Exception('Activa la ubicacion del dispositivo para ver el mapa.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw Exception('La app no tiene permiso para acceder a tu ubicacion.');
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
