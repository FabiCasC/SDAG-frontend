import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/maps/google_places_service.dart';
import '../../../shared/maps/widgets/places_address_search_field.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

class PickupReservaScreen extends ConsumerStatefulWidget {
  const PickupReservaScreen({super.key});

  @override
  ConsumerState<PickupReservaScreen> createState() => _PickupReservaScreenState();
}

class _PickupReservaScreenState extends ConsumerState<PickupReservaScreen> {
  static const _lima = LatLng(-12.1092, -77.0365);

  late final TextEditingController _addressController;

  GoogleMapController? _mapController;
  bool _loadingContext = true;
  bool _resolvingGeo = false;
  bool _ignoreAddressEvents = false;

  String? _puntoSeleccionado;
  LatLng? _coordenadasSeleccionadas;

  String _preferredFromProfile = '';
  List<String> _routePickupAddresses = const [];
  String? _contextError;
  String? _contextLoadTripId;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestLocationPermission());
  }

  Future<void> _requestLocationPermission() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      !_loadingContext &&
      !_resolvingGeo &&
      _puntoSeleccionado != null &&
      _puntoSeleccionado!.trim().length >= 3 &&
      _coordenadasSeleccionadas != null;

  Set<Marker> get _markers {
    final coords = _coordenadasSeleccionadas;
    if (coords == null) return const {};
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: coords,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  void _clearSelection() {
    setState(() {
      _puntoSeleccionado = null;
      _coordenadasSeleccionadas = null;
    });
  }

  void _onAddressEdited() {
    if (_ignoreAddressEvents) return;
    _clearSelection();
  }

  Future<void> _applyMapSelection({
    required String address,
    required LatLng coords,
  }) async {
    _ignoreAddressEvents = true;
    _addressController.text = address;
    _ignoreAddressEvents = false;

    setState(() {
      _puntoSeleccionado = address;
      _coordenadasSeleccionadas = coords;
      _resolvingGeo = false;
    });

    final controller = _mapController;
    if (controller != null) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(coords, 15));
    }
  }

  Future<void> _confirmAddress(String address, {LatLng? coords}) async {
    final trimmed = address.trim();
    if (trimmed.length < 3) return;

    setState(() {
      _resolvingGeo = true;
      _puntoSeleccionado = null;
      _coordenadasSeleccionadas = null;
    });

    var position = coords ?? await GooglePlacesService.geocodeAddress(trimmed);
    if (!mounted) return;

    if (position == null) {
      setState(() => _resolvingGeo = false);
      AppSnackbars.warning(
        context,
        'No se pudo ubicar la dirección en el mapa. Elige una sugerencia o toca el mapa.',
      );
      return;
    }

    await _applyMapSelection(address: trimmed, coords: position);
  }

  Future<void> _onPlaceChosen(PlacePrediction prediction, String displayText) async {
    final address = displayText.trim();
    final coords = await GooglePlacesService.latLngForPlaceId(prediction.placeId);
    if (!mounted) return;
    if (coords == null) {
      await _confirmAddress(address);
      return;
    }
    await _applyMapSelection(address: address, coords: coords);
  }

  Future<void> _onMapTap(LatLng coords) async {
    setState(() {
      _resolvingGeo = true;
      _puntoSeleccionado = null;
      _coordenadasSeleccionadas = null;
    });

    final address = await GooglePlacesService.reverseGeocode(coords.latitude, coords.longitude);
    if (!mounted) return;

    final resolved = (address != null && address.trim().isNotEmpty)
        ? address.trim()
        : '${coords.latitude.toStringAsFixed(5)}, ${coords.longitude.toStringAsFixed(5)}';

    await _applyMapSelection(address: resolved, coords: coords);
  }

  Future<void> _loadContextForTrip(String tripId) async {
    if (!mounted) return;
    if (tripId.trim().isEmpty) {
      setState(() {
        _loadingContext = false;
        _contextError = 'Este viaje no tiene identificador; no se pueden cargar puntos de ruta.';
      });
      return;
    }

    setState(() {
      _loadingContext = true;
      _contextError = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      var preferred = '';
      if (userId != null) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('preferred_pickup')
            .eq('id', userId)
            .maybeSingle();
        preferred = row?['preferred_pickup']?.toString().trim() ?? '';
      }

      final trip = await Supabase.instance.client.from('trips').select('route_id').eq('id', tripId).maybeSingle();
      final routeId = trip?['route_id']?.toString();
      var routePoints = <String>[];
      if (routeId != null && routeId.isNotEmpty) {
        final pts = await Supabase.instance.client
            .from('pickup_points')
            .select('address')
            .eq('route_id', routeId)
            .order('address', ascending: true);
        for (final raw in pts as List) {
          final m = Map<String, dynamic>.from(raw as Map);
          final a = m['address']?.toString().trim();
          if (a != null && a.isNotEmpty) routePoints.add(a);
        }
      }

      if (!mounted) return;
      setState(() {
        _preferredFromProfile = preferred;
        _routePickupAddresses = routePoints;
      });
      await _syncInitialPickup();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contextError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingContext = false;
        });
      }
    }
  }

  Future<void> _syncInitialPickup() async {
    final reserva = ref.read(reservaProvider);
    final current = reserva.puntoRecojo?.trim();
    final lat = reserva.pickupLat;
    final lng = reserva.pickupLng;

    if (current != null && current.isNotEmpty) {
      if (lat != null && lng != null) {
        await _applyMapSelection(address: current, coords: LatLng(lat, lng));
        return;
      }
      await _confirmAddress(current);
      return;
    }
    if (_preferredFromProfile.isNotEmpty) {
      await _confirmAddress(_preferredFromProfile);
      return;
    }
    if (_routePickupAddresses.isNotEmpty) {
      await _confirmAddress(_routePickupAddresses.first);
    }
  }

  Future<void> _onContinue() async {
    if (!_canContinue) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Por favor selecciona un punto de recojo en el mapa o en las sugerencias.');
      return;
    }

    final text = _puntoSeleccionado!.trim();
    final coords = _coordenadasSeleccionadas!;
    ref.read(reservaProvider.notifier).setPickupWithCoords(
      text,
      lat: coords.latitude,
      lng: coords.longitude,
    );

    if (mounted) context.push(AppRoutes.passengerReservaResumen);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driver = ref.read(reservaProvider).conductorSeleccionado;
    if (driver == null) return;
    final tripId = driver.tripId.trim();
    if (tripId.isEmpty) {
      if (_contextLoadTripId != '') {
        _contextLoadTripId = '';
        scheduleMicrotask(() {
          if (mounted) {
            setState(() {
              _loadingContext = false;
              _contextError = 'Viaje sin ID; vuelve a elegir asientos.';
            });
          }
        });
      }
      return;
    }
    if (_contextLoadTripId == tripId) return;
    _contextLoadTripId = tripId;
    scheduleMicrotask(() {
      if (mounted) unawaited(_loadContextForTrip(tripId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(reservaProvider).conductorSeleccionado;

    if (driver == null) {
      return const AppScaffold(
        title: 'Punto de recojo',
        body: PlaceholderPage(
          title: 'Reserva incompleta',
          subtitle: 'Vuelve a seleccionar conductor y asientos.',
        ),
      );
    }

    final selected = _puntoSeleccionado?.trim() ?? '';

    return AppScaffold(
      title: 'Punto de recojo',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ruta del conductor',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            driver.routeLabel,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_loadingContext) const LinearProgressIndicator(),
                  if (_resolvingGeo) const LinearProgressIndicator(),
                  if (_contextError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'No se pudieron cargar los puntos de ruta: $_contextError',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                    ),
                  PlacesAddressSearchField(
                    controller: _addressController,
                    label: '¿Dónde te recogemos?',
                    hint: 'Escribe tu dirección...',
                    prefixIcon: Icons.location_on_rounded,
                    onTextEdited: _onAddressEdited,
                    onAddressResolved: (formatted) => unawaited(_confirmAddress(formatted)),
                    onPlaceChosen: (p, text) => unawaited(_onPlaceChosen(p, text)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Toca el mapa para elegir el punto exacto',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(target: _lima, zoom: 13),
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: _markers,
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                        },
                        onMapCreated: (c) {
                          _mapController = c;
                          Geolocator.getCurrentPosition().then((pos) {
                            if (!mounted) return;
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(pos.latitude, pos.longitude),
                                15,
                              ),
                            );
                          }).catchError((_) {});
                        },
                        onTap: (coords) => unawaited(_onMapTap(coords)),
                        zoomControlsEnabled: true,
                      ),
                    ),
                  ),
                  if (selected.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Punto seleccionado: $selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  if (_preferredFromProfile.isNotEmpty) ...[
                    Text(
                      'Tu punto favorito',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ChoiceChip(
                        label: Text(_preferredFromProfile, overflow: TextOverflow.ellipsis),
                        selected: selected == _preferredFromProfile,
                        onSelected: (_) => unawaited(_confirmAddress(_preferredFromProfile)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_routePickupAddresses.isNotEmpty) ...[
                    Text(
                      'Puntos de la ruta',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _routePickupAddresses.map((p) {
                        return ChoiceChip(
                          label: Text(p, overflow: TextOverflow.ellipsis),
                          selected: selected == p,
                          onSelected: (_) => unawaited(_confirmAddress(p)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: 'Continuar',
            onPressed: _canContinue
                ? () {
                    unawaited(_onContinue());
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
