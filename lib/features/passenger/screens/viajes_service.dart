import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio que maneja las consultas de viajes a Supabase.
/// Usa las tablas reales del proyecto: trips, drivers, routes.
class ViajesService {
  /// Cliente de Supabase (singleton global)
  final _supabase = Supabase.instance.client;

  /// Busca viajes disponibles según la dirección seleccionada.
  /// 
  /// [direccion] puede ser:
  /// - 'san_isidro_chosica' → viajes de San Isidro hacia Chosica
  /// - 'chosica_san_isidro' → viajes de Chosica hacia San Isidro
  /// 
  /// Solo devuelve viajes en estado 'en_ruta' o 'scheduled'.
  /// Ordenados por hora de salida más próxima.
  Future<List<Map<String, dynamic>>> buscarViajesDisponibles({
    required String direccion,
  }) async {
    final response = await _supabase
        .from('trips')
        .select('''
          id,
          status,
          scheduled_departure_at,
          base_fare,
          amount_total,
          routes (
            id
          ),
          drivers (
            plate,
            vehicle_type,
            capacity,
            estado
          )
        ''')
        .inFilter('status', ['en_ruta', 'scheduled'])
        .order('scheduled_departure_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}