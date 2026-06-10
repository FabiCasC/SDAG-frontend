import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/config/google_maps_config.dart';

class PlacePrediction {
  const PlacePrediction({required this.placeId, required this.description});

  final String placeId;
  final String description;
}

/// Autocomplete y detalle de lugares (Google Places API, JSON legacy).
class GooglePlacesService {
  GooglePlacesService._();

  static Future<List<PlacePrediction>> autocomplete(String input) async {
    final q = input.trim();
    if (q.length < 2) return const [];

    final key = googleMapsRestApiKey();
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(q)}'
      '&key=$key'
      '&components=country:pe'
      '&language=es',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return const [];

    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) return const [];
    final preds = map['predictions'];
    if (preds is! List) return const [];

    return preds
        .whereType<Map>()
        .map((raw) {
          final m = Map<String, dynamic>.from(raw);
          final id = m['place_id']?.toString() ?? '';
          final desc = m['description']?.toString() ?? '';
          if (id.isEmpty || desc.isEmpty) return null;
          return PlacePrediction(placeId: id, description: desc);
        })
        .whereType<PlacePrediction>()
        .toList();
  }

  /// Dirección legible para guardar en `preferred_pickup` / `pickup_point`.
  static Future<LatLng?> latLngForPlaceId(String placeId) async {
    if (placeId.isEmpty) return null;
    final key = googleMapsRestApiKey();
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${Uri.encodeComponent(placeId)}'
      '&fields=geometry'
      '&key=$key'
      '&language=es',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) return null;
    final result = map['result'];
    if (result is! Map<String, dynamic>) return null;
    final geom = result['geometry'];
    if (geom is! Map<String, dynamic>) return null;
    final loc = geom['location'];
    if (loc is! Map<String, dynamic>) return null;
    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  static Future<String?> formattedAddressForPlaceId(String placeId) async {
    if (placeId.isEmpty) return null;
    final key = googleMapsRestApiKey();
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${Uri.encodeComponent(placeId)}'
      '&fields=formatted_address,name'
      '&key=$key'
      '&language=es',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) return null;
    final result = map['result'];
    if (result is! Map<String, dynamic>) return null;
    final formatted = result['formatted_address']?.toString().trim();
    if (formatted != null && formatted.isNotEmpty) return formatted;
    final name = result['name']?.toString().trim();
    return (name != null && name.isNotEmpty) ? name : null;
  }

  static Future<String?> reverseGeocode(double lat, double lng) async {
    final key = googleMapsRestApiKey();
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng'
      '&key=$key'
      '&language=es',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) return null;
    final results = map['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map<String, dynamic>) return null;
    final addr = first['formatted_address']?.toString().trim();
    return (addr != null && addr.isNotEmpty) ? addr : null;
  }
}
