import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/config/google_maps_config.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/maps/google_places_service.dart';
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
  bool _buscando = false;

  List<PlacePrediction> _sugerencias = [];
  String? _puntoSeleccionado;
  LatLng? _coordenadasSeleccionadas;
  bool _sinResultados = false;
  String _ultimaBusqueda = '';

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
      !_buscando &&
      _puntoSeleccionado != null &&
      _puntoSeleccionado!.trim().isNotEmpty &&
      _coordenadasSeleccionadas != null;

  Set<Marker> get _markers {
    final coords = _coordenadasSeleccionadas;
    if (coords == null) return const {};
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: coords,
        infoWindow: InfoWindow(title: _puntoSeleccionado ?? 'Punto de recojo'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  void _clearSelection() {
    setState(() {
      _addressController.clear();
      _puntoSeleccionado = null;
      _coordenadasSeleccionadas = null;
      _sugerencias = [];
      _sinResultados = false;
      _ultimaBusqueda = '';
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _buscando = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final key = googleMapsRestApiKey();
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&language=es'
        '&key=$key',
      );
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final direccion = data['results'][0]['formatted_address'].toString();
        final coords = LatLng(position.latitude, position.longitude);
        await _applySelection(address: direccion, coords: coords);
      } else if (mounted) {
        AppSnackbars.error(context, 'No se pudo obtener tu ubicacion');
      }
    } catch (_) {
      if (mounted) {
        AppSnackbars.error(context, 'No se pudo obtener tu ubicacion');
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _onMapTap(LatLng coords) async {
    setState(() => _buscando = true);
    try {
      final key = googleMapsRestApiKey();
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${coords.latitude},${coords.longitude}'
        '&language=es'
        '&key=$key',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final direccion = data['results'][0]['formatted_address'].toString();
        await _applySelection(address: direccion, coords: coords);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _applySelection({
    required String address,
    required LatLng coords,
  }) async {
    setState(() {
      _addressController.text = address;
      _puntoSeleccionado = address;
      _coordenadasSeleccionadas = coords;
      _sugerencias = [];
      _resolvingGeo = false;
      _buscando = false;
    });

    final controller = _mapController;
    if (controller != null) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(coords, 16));
    }
  }

  Future<void> _confirmAddress(String address, {LatLng? coords, bool silent = true}) async {
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
      debugPrint('[Geocode] No se pudo ubicar chip/favorito: $trimmed');
      setState(() => _resolvingGeo = false);
      if (!silent && mounted) {
        AppSnackbars.error(context, 'Por favor selecciona un punto de recojo en las sugerencias.');
      }
      return;
    }

    await _applySelection(address: trimmed, coords: position);
  }

  Future<void> _onSuggestionTap(PlacePrediction prediction) async {
    final seleccionado = prediction.description;
    setState(() {
      _addressController.text = seleccionado;
      _sugerencias = [];
      _puntoSeleccionado = seleccionado;
      _buscando = true;
      _resolvingGeo = true;
    });

    try {
      LatLng? coords;
      if (prediction.placeId.isNotEmpty) {
        coords = await GooglePlacesService.latLngForPlaceId(prediction.placeId);
      }
      coords ??= await GooglePlacesService.geocodeAddress(seleccionado);
      if (!mounted) return;

      if (coords == null) {
        debugPrint('[Geocode] No se pudo obtener coordenadas para: $seleccionado');
        setState(() {
          _buscando = false;
          _resolvingGeo = false;
          _puntoSeleccionado = null;
        });
        return;
      }

      await _applySelection(address: seleccionado, coords: coords);
    } catch (_) {
      if (mounted) {
        setState(() {
          _buscando = false;
          _resolvingGeo = false;
          _puntoSeleccionado = null;
        });
      }
    }
  }

  Future<void> _onAddressChanged(String value) async {
    if (value.trim() != (_puntoSeleccionado ?? '').trim()) {
      setState(() {
        _puntoSeleccionado = null;
        _coordenadasSeleccionadas = null;
      });
    }

    if (value.length < 3) {
      setState(() {
        _sugerencias = [];
        _sinResultados = false;
        _ultimaBusqueda = '';
      });
      return;
    }

    setState(() {
      _buscando = true;
      _sinResultados = false;
      _ultimaBusqueda = value;
    });

    final key = googleMapsRestApiKey();
    var sugerencias = <PlacePrediction>[];

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(value)}'
        '&components=country:pe'
        '&language=es'
        '&key=$key',
      );
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? '';
      final preds = data['predictions'];
      final count = preds is List ? preds.length : 0;
      debugPrint('[Places] status=$status predictions=$count');

      if (status == 'OK' && preds is List) {
        sugerencias = preds
            .whereType<Map>()
            .map((raw) {
              final m = Map<String, dynamic>.from(raw);
              final id = m['place_id']?.toString() ?? '';
              final desc = m['description']?.toString() ?? '';
              if (id.isEmpty || desc.isEmpty) return null;
              return PlacePrediction(placeId: id, description: desc);
            })
            .whereType<PlacePrediction>()
            .take(5)
            .toList();
      } else if (status == 'ZERO_RESULTS') {
        sugerencias = [];
      } else {
        debugPrint('[Places] ERROR: $status - ${data['error_message']}');
        sugerencias = [];
      }
    } catch (e) {
      debugPrint('[Places] Exception: $e');
    }

    if (sugerencias.isEmpty && value.length >= 3) {
      try {
        final geoUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent('$value, Lima, Peru')}'
          '&key=$key',
        );
        final geoRes = await http.get(geoUrl);
        final geoData = jsonDecode(geoRes.body) as Map<String, dynamic>;
        final geoStatus = geoData['status']?.toString() ?? '';
        final results = geoData['results'];
        final geoCount = results is List ? results.length : 0;
        debugPrint('[Geocode] status=$geoStatus results=$geoCount');

        if (geoStatus == 'OK' && results is List) {
          sugerencias = results
              .whereType<Map>()
              .map((raw) {
                final m = Map<String, dynamic>.from(raw);
                final desc = m['formatted_address']?.toString() ?? '';
                if (desc.isEmpty) return null;
                return PlacePrediction(placeId: '', description: desc);
              })
              .whereType<PlacePrediction>()
              .take(5)
              .toList();
        } else if (geoStatus != 'OK') {
          debugPrint('[Geocode] ERROR: $geoStatus - ${geoData['error_message']}');
        }
      } catch (e) {
        debugPrint('[Geocode] Exception: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _sugerencias = sugerencias;
      _sinResultados = sugerencias.isEmpty && value.length >= 3;
      _buscando = false;
    });
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

    if (current != null && current.isNotEmpty && lat != null && lng != null) {
      await _applySelection(address: current, coords: LatLng(lat, lng));
      return;
    }

    // Solo prellenar texto; no geocodificar ni mostrar errores automáticamente.
    final prefill = current ??
        (_preferredFromProfile.isNotEmpty ? _preferredFromProfile : null) ??
        (_routePickupAddresses.isNotEmpty ? _routePickupAddresses.first : null);
    if (prefill != null && prefill.isNotEmpty && mounted) {
      setState(() => _addressController.text = prefill);
    }
  }

  Future<void> _onContinue() async {
    if (!_canContinue) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Por favor selecciona un punto de recojo en las sugerencias.');
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

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: '¿Dónde te recogemos?',
            hintText: 'Escribe tu dirección o referencia...',
            prefixIcon: const Icon(Icons.location_on_rounded),
            suffixIcon: _buscando || _resolvingGeo
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _puntoSeleccionado != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSelection,
                      )
                    : null,
          ),
          onChanged: (value) => unawaited(_onAddressChanged(value)),
        ),
        if (_sinResultados &&
            !_buscando &&
            _addressController.text.trim().length >= 3 &&
            _addressController.text.trim() == _ultimaBusqueda.trim())
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Sin resultados para esta búsqueda',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        if (_sugerencias.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sugerencias.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final prediction = _sugerencias[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 20),
                  title: Text(
                    prediction.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => unawaited(_onSuggestionTap(prediction)),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickPickups(String selected) {
    if (_preferredFromProfile.isEmpty && _routePickupAddresses.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_preferredFromProfile.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(_preferredFromProfile, overflow: TextOverflow.ellipsis),
                selected: selected == _preferredFromProfile,
                onSelected: (_) => unawaited(_confirmAddress(_preferredFromProfile)),
              ),
            ),
          ..._routePickupAddresses.map((p) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(p, overflow: TextOverflow.ellipsis),
                selected: selected == p,
                onSelected: (_) => unawaited(_confirmAddress(p)),
              ),
            );
          }),
        ],
      ),
    );
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
      padding: EdgeInsets.zero,
      fallbackRoute: AppRoutes.passengerSeatMap,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  driver.routeLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_loadingContext) const LinearProgressIndicator(),
                if (_contextError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'No se pudieron cargar los puntos de ruta: $_contextError',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
                _buildSearchField(),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Usar mi ubicacion actual'),
                  onPressed: _buscando || _resolvingGeo ? null : () => unawaited(_useCurrentLocation()),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildQuickPickups(selected),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: _lima, zoom: 13),
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                zoomControlsEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers,
                onTap: (coords) => unawaited(_onMapTap(coords)),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                onMapCreated: (controller) {
                  _mapController = controller;
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppPrimaryButton(
              label: 'Continuar',
              onPressed: _canContinue ? () => unawaited(_onContinue()) : null,
            ),
          ),
        ],
      ),
    );
  }
}
