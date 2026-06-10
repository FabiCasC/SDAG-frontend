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

  /// Registra una nueva reserva vinculando pasajero, chofer y viaje.
  Future<void> crearReserva({
    required String tripId,
    required String passengerId,
    required String driverId,
    required double amount,
    required List<int> seats,
  }) async {
    await _supabase.from('bookings').insert({
      'trip_id': tripId,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'amount': amount,
      'seats': seats,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Obtiene las reservas asignadas a un chofer específico.
  /// Solo devuelve reservas de viajes que pertenecen al chofer.
  Future<List<Map<String, dynamic>>> obtenerReservasPorConductor(String driverId) async {
    final response = await _supabase
        .from('bookings')
        .select('''
          id,
          status,
          seats,
          created_at,
          profiles:passenger_id (
            full_name
          ),
          trips (
            drivers (
              capacity
            ),
            scheduled_departure_at,
            routes (
              from_label,
              to_label
            )
          )
        ''')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Valida y registra el abordaje de un pasajero en la base de datos real.
  Future<bool> registrarAbordaje(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .update({'status': 'boarded'})
          .eq('id', bookingId)
          .select();
      
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el conteo total de reservas activas (pendientes o confirmadas) en el sistema.
  Future<int> obtenerConteoReservasActivas() async {
    final response = await _supabase
        .from('bookings')
        .select('id')
        .or('status.eq.pending,status.eq.confirmed')
        .count(CountOption.exact);
    
    return response.count;
  }
}