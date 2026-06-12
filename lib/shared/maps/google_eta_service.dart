import 'dart:convert';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/google_maps_config.dart';
import 'google_places_service.dart';

/// ETA y geocodificación con caché en memoria para reducir llamadas a Google.
class GoogleEtaService {
  GoogleEtaService._();

  static final Map<String, LatLng> _geocodeCache = {};

  /// Geocodifica una dirección como máximo una vez por sesión.
  static Future<LatLng?> resolvePickupCoords({
    required String pickupAddress,
    double? pickupLat,
    double? pickupLng,
  }) async {
    if (pickupLat != null && pickupLng != null) {
      return LatLng(pickupLat, pickupLng);
    }

    final key = pickupAddress.trim().toLowerCase();
    if (key.isEmpty) return null;

    final cached = _geocodeCache[key];
    if (cached != null) return cached;

    final coords = await GooglePlacesService.geocodeAddress(pickupAddress);
    if (coords != null) {
      _geocodeCache[key] = coords;
    }
    return coords;
  }

  /// Distance Matrix — una llamada por invocación.
  static Future<int?> etaMinutesBetween({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final key = googleMapsRestApiKey();
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=$originLat,$originLng'
      '&destinations=$destLat,$destLng'
      '&departure_time=now'
      '&traffic_model=best_guess'
      '&key=$key&language=es',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['status'] != 'OK') return null;

      final rows = data['rows'];
      if (rows is! List || rows.isEmpty) return null;

      final elements = (rows.first as Map<String, dynamic>)['elements'];
      if (elements is! List || elements.isEmpty) return null;

      final element = elements.first as Map<String, dynamic>;
      if (element['status'] != 'OK') return null;

      final traffic = element['duration_in_traffic'];
      final duration = element['duration'];
      final seconds = (traffic is Map ? traffic['value'] : null) as num? ??
          (duration is Map ? duration['value'] : null) as num?;
      if (seconds == null) return null;

      return (seconds / 60).round();
    } catch (_) {
      return null;
    }
  }

  /// ETA conductor → punto de recojo (driver_locations + geocode + Distance Matrix).
  static Future<int?> calcularEtaConductorAlPickup({
    required String driverId,
    required String pickupAddress,
    double? pickupLat,
    double? pickupLng,
    LatLng? conductorPos,
  }) async {
    LatLng? origin = conductorPos;

    if (origin == null) {
      final driverLocation = await Supabase.instance.client
          .from('driver_locations')
          .select('lat, lng')
          .eq('driver_id', driverId)
          .maybeSingle();

      final lat = (driverLocation?['lat'] as num?)?.toDouble() ?? -12.1092;
      final lng = (driverLocation?['lng'] as num?)?.toDouble() ?? -77.0365;
      origin = LatLng(lat, lng);
    }

    final destination = await resolvePickupCoords(
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
    );
    if (destination == null) return null;

    return etaMinutesBetween(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destLat: destination.latitude,
      destLng: destination.longitude,
    );
  }

  /// Distancia en metros sin llamar a Google (Haversine).
  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
