import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/config/google_maps_config.dart';

List<LatLng> decodeDirectionsPolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  while (index < encoded.length) {
    var shift = 0;
    var result = 0;
    int b;
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

/// Polyline San Isidro → Chosica (una sola llamada Directions API).
Future<List<LatLng>> fetchRoutePolyline({
  LatLng? origin,
  LatLng? destination,
}) async {
  final from = origin ?? const LatLng(-12.0992, -77.0342);
  final to = destination ?? const LatLng(-11.9429, -76.7094);
  final key = googleMapsRestApiKey();
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/directions/json'
    '?origin=${from.latitude},${from.longitude}'
    '&destination=${to.latitude},${to.longitude}'
    '&key=$key&language=es',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode != 200) return [from, to];
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['status'] != 'OK') return [from, to];
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return [from, to];
    final encoded = routes.first['overview_polyline']?['points']?.toString();
    if (encoded == null || encoded.isEmpty) return [from, to];
    return decodeDirectionsPolyline(encoded);
  } catch (_) {
    return [from, to];
  }
}
