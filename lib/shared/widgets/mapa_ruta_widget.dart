import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../data/models/route_polyline_model.dart';

class MapaRutaWidget extends StatefulWidget {
  final RoutePolyline routePolyline;

  const MapaRutaWidget({Key? key, required this.routePolyline}) : super(key: key);

  @override
  State<MapaRutaWidget> createState() => _MapaRutaWidgetState();
}

class _MapaRutaWidgetState extends State<MapaRutaWidget> {
  late GoogleMapController _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];
  bool _loading = true;

  static const String _apiKey = 'AIzaSyBspcTEh828O90o862FewdtQeCek9MIXOk';

  @override
  void initState() {
    super.initState();
    _cargarRutaReal();
  }

  Future<void> _cargarRutaReal() async {
    final points = widget.routePolyline.points;

    // 🔍 DEBUG: ver cuántos puntos llegan
    print('🗺️ [MapaRuta] puntos recibidos: ${points.length}');
    for (var i = 0; i < points.length; i++) {
      print('🗺️ [MapaRuta] punto[$i]: lat=${points[i].lat}, lng=${points[i].lng}');
    }

    if (points.length < 2) {
      print('🗺️ [MapaRuta] ❌ menos de 2 puntos, abortando');
      return;
    }

    final origin = '${points.first.lat},${points.first.lng}';
    final destination = '${points.last.lat},${points.last.lng}';

    String waypointsParam = '';
    if (points.length > 2) {
      final waypoints = points
          .sublist(1, points.length - 1)
          .map((p) => '${p.lat},${p.lng}')
          .join('|');
      waypointsParam = '&waypoints=$waypoints';
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$origin'
          '&destination=$destination'
          '$waypointsParam'
          '&key=$_apiKey',
    );

    // 🔍 DEBUG: ver la URL exacta que se envía
    print('🗺️ [MapaRuta] URL: $url');

    try {
      final response = await http.get(url);

      // 🔍 DEBUG: ver respuesta completa
      print('🗺️ [MapaRuta] STATUS HTTP: ${response.statusCode}');
      print('🗺️ [MapaRuta] BODY: ${response.body}');

      final data = jsonDecode(response.body);
      final status = data['status'];
      print('🗺️ [MapaRuta] Google status: $status');

      if (status == 'OK') {
        final encoded = data['routes'][0]['overview_polyline']['points'] as String;
        _routePoints = _decodePolyline(encoded);
        print('🗺️ [MapaRuta] ✅ ruta decodificada con ${_routePoints.length} puntos');
      } else {
        print('🗺️ [MapaRuta] ⚠️ Directions falló ($status), usando fallback de puntos directos');
        if (data['error_message'] != null) {
          print('🗺️ [MapaRuta] error_message: ${data['error_message']}');
        }
        _routePoints = points.map((p) => LatLng(p.lat, p.lng)).toList();
      }
    } catch (e) {
      print('🗺️ [MapaRuta] ❌ excepción: $e');
      _routePoints = points.map((p) => LatLng(p.lat, p.lng)).toList();
    }

    _construirMapa();
  }

  void _construirMapa() {
    if (_routePoints.isEmpty) {
      print('🗺️ [MapaRuta] ❌ _routePoints vacío, no se construye el mapa');
      return;
    }

    print('🗺️ [MapaRuta] ✅ construyendo mapa con ${_routePoints.length} puntos');

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('ruta_real'),
        points: _routePoints,
        color: const Color(0xFF1E88E5),
        width: 5,
      ),
    );

    _markers.add(Marker(
      markerId: const MarkerId('inicio'),
      position: _routePoints.first,
      infoWindow: const InfoWindow(title: 'Origen'),
    ));

    _markers.add(Marker(
      markerId: const MarkerId('fin'),
      position: _routePoints.last,
      infoWindow: const InfoWindow(title: 'Destino'),
    ));

    setState(() => _loading = false);
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;

      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _routePoints.first,
          zoom: 11.5,
        ),
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        tiltGesturesEnabled: true,
        rotateGesturesEnabled: true,
        polylines: _polylines,
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
          _ajustarCamara();
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }

  void _ajustarCamara() {
    if (_routePoints.isEmpty) return;
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }
}