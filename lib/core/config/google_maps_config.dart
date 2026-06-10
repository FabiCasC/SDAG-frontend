import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Clave para Places / Geocoding REST (misma que Mapas si el proyecto lo permite).
String googleMapsRestApiKey() {
  final fromEnv = (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '').trim();
  if (fromEnv.isNotEmpty) return fromEnv;
  // Fallback al key ya usado en pantallas de mapa del proyecto (solo desarrollo).
  return 'AIzaSyBspcTEh828O90o862FewdtQeCek9MIXOk';
}
