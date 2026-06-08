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
    required this.etaMinutes,
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
  final int etaMinutes;
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
      // Determinar el route_id según la dirección
      // Tabla routes: 'San Isidro → Chosica' o 'Chosica → San Isidro'
      final fromLabel = direction == 'si_cho' ? 'San Isidro' : 'Chosica';

      // Buscar el route_id correspondiente
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
              rating_count,
              profile_id
            )
          ''')
          .eq('route_id', routeId)
          .inFilter('status', ['en_ruta', 'scheduled'])
          .order('scheduled_departure_at', ascending: true);

      final List<ViajeDisponible> result = [];

      for (final trip in tripsRes) {
        final driver = trip['drivers'] as Map<String, dynamic>?;
        if (driver == null) continue;
        if (driver['estado'] != 'disponible' && driver['estado'] != 'en_ruta') continue;

        // Calcular asientos disponibles
        final totalSeats = (driver['capacity'] as int?) ?? 0;
        final tripId = trip['id'] as String;

        // Contar reservas activas para este viaje
        final reservationsRes = await _supabase
            .from('reservations')
            .select('id')
            .eq('trip_id', tripId)
            .eq('status', 'active');

        final occupiedSeats = (reservationsRes as List).length;
        final availableSeats = totalSeats - occupiedSeats;

        if (availableSeats <= 0) continue;

        result.add(ViajeDisponible(
          tripId: tripId,
          driverId: driver['id'] as String,
          driverName: 'Conductor', // se puede mejorar con join a profiles
          plate: driver['plate'] as String? ?? '',
          vehicleType: driver['vehicle_type'] as String? ?? '',
          totalSeats: totalSeats,
          availableSeats: availableSeats,
          routeLabel: routeName,
          rating: (driver['rating_avg'] as num?)?.toDouble() ?? 0.0,
          ratingCount: (driver['rating_count'] as int?) ?? 0,
          etaMinutes: 0,
          direction: direction,
          status: driver['estado'] as String? ?? '',
        ));
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}