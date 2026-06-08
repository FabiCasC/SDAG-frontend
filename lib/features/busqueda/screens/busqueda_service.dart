import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo que representa un conductor/viaje disponible
/// adaptado desde las tablas reales de Supabase.
class ViajeDisponible {
  const ViajeDisponible({
    required this.tripId,
    required this.driverId,
    required this.driverName,
    required this.plate,
    required this.vehicleType,
    required this.totalSeats,
    required this.availableSeats,
    required this.routeLabel,
    required this.rating,
    required this.ratingCount,
    required this.direction,
    required this.status,
  });

  final String tripId;
  final String driverId;
  final String driverName;
  final String plate;
  final String vehicleType;
  final int totalSeats;
  final int availableSeats;
  final String routeLabel;
  final double rating;
  final int ratingCount;
  final String direction;
  final String status;
}

/// Servicio que consulta viajes disponibles desde Supabase.
/// Reemplaza los datos mock de MockData.drivers.
class BusquedaService {
  final _supabase = Supabase.instance.client;

  /// Busca viajes disponibles según la dirección.
  /// [direction] puede ser 'si_cho' o 'cho_si'
  Future<List<ViajeDisponible>> buscarViajes(String direction) async {
    try {
      // Determinar from_label según dirección
      final fromLabel = direction == 'si_cho' ? 'San Isidro' : 'Chosica';

      // Buscar el route_id correspondiente en tabla routes
      final routeRes = await _supabase
          .from('routes')
          .select('id, name, from_label, to_label')
          .eq('from_label', fromLabel)
          .eq('active', true)
          .maybeSingle();

      if (routeRes == null) return [];

      final routeId = routeRes['id'] as String;
      final routeName = routeRes['name'] as String;

      // Buscar viajes activos en esa ruta
      final tripsRes = await _supabase
          .from('trips')
          .select('''
            id,
            status,
            scheduled_departure_at,
            base_fare,
            drivers (
              id,
              plate,
              vehicle_type,
              capacity,
              estado,
              rating_avg,
              rating_count
            )
          ''')
          .eq('route_id', routeId)
          .neq('status', 'completado')
          .order('scheduled_departure_at', ascending: true);

      final List<ViajeDisponible> result = [];

      for (final trip in tripsRes) {
        final driver = trip['drivers'] as Map<String, dynamic>?;
        final tripId = trip['id'] as String;
        final totalSeats = (driver?['capacity'] as int?) ?? 14;

        // Contar reservas activas para calcular asientos disponibles
        final reservationsRes = await _supabase
            .from('reservations')
            .select('id')
            .eq('trip_id', tripId)
            .eq('status', 'activa');

        final occupiedSeats = (reservationsRes as List).length;
        final availableSeats = totalSeats - occupiedSeats;

        if (availableSeats <= 0) continue;

        result.add(ViajeDisponible(
          tripId: tripId,
          driverId: driver?['id'] as String? ?? tripId,
          driverName: 'Conductor',
          plate: driver?['plate'] as String? ?? 'Sin placa',
          vehicleType: driver?['vehicle_type'] as String? ?? 'Combi',
          totalSeats: totalSeats,
          availableSeats: availableSeats,
          routeLabel: routeName,
          rating: (driver?['rating_avg'] as num?)?.toDouble() ?? 0.0,
          ratingCount: (driver?['rating_count'] as int?) ?? 0,
          direction: direction,
          status: trip['status'] as String? ?? '',
        ));
      }

      return result;
    } catch (e) {
      print('ERROR buscarViajes: $e');
      return [];
    }
  }
}