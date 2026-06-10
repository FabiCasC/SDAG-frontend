import 'package:supabase_flutter/supabase_flutter.dart';

class ViajesService {
  // 1. Asegúrate de que esta línea exista aquí arriba
  final _supabase = Supabase.instance.client;

  /// Busca viajes disponibles usando las relaciones correctas en Supabase
  /// y extrae la polyline de la ruta para renderizar el mapa.
  Future<List<Map<String, dynamic>>> buscarViajesDisponibles({
    required String routeId,
  }) async {
    // 2. Aquí usamos _supabase con las comillas simples triples para el select
    final response = await _supabase
        .from('trips')
        .select('''
          id,
          scheduled_departure_at,
          amount,
          drivers (
            id,
            plate,
            vehicle_type,
            capacity,
            profile_id
          ),
          routes (
            id,
            name,
            from_label,
            to_label,
            polyline
          )
        ''')
        .eq('route_id', routeId);

    return List<Map<String, dynamic>>.from(response);
  }
}