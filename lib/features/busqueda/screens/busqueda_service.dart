import 'package:supabase_flutter/supabase_flutter.dart';

import '../../reserva/providers/reserva_provider.dart';

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

  ReservaDriverInfo toReservaDriverInfo() {
    return ReservaDriverInfo(
      tripId: tripId,
      driverId: driverId,
      name: driverName,
      plate: plate,
      vehicleType: vehicleType,
      totalSeats: totalSeats,
      routeLabel: routeLabel,
      rating: rating,
      ratingCount: ratingCount,
      status: status,
    );
  }
}

/// Servicio que consulta viajes disponibles desde Supabase.
/// Reemplaza los datos mock de MockData.drivers.
class BusquedaService {
  final _supabase = Supabase.instance.client;

  /// Busca viajes disponibles según la dirección.
  /// [direction] puede ser 'si_cho' o 'cho_si'
  Future<List<ViajeDisponible>> buscarViajes(String direction) async {
    try {
      final fromLabel = direction == 'si_cho' ? 'San Isidro' : 'Chosica';
      final driversRes = await _supabase
          .from('drivers')
          .select('''
            id,
            plate,
            vehicle_type,
            capacity,
            estado,
            rating_avg,
            rating_count,
            profiles (
              id,
              name,
              first_name,
              last_name
            )
          ''')
          .eq('cuenta_activa', true)
          .neq('estado', 'inactivo');

      final List<ViajeDisponible> result = [];

      for (final rawDriver in driversRes) {
        final driver = Map<String, dynamic>.from(rawDriver as Map);
        final driverId = driver['id']?.toString();
        if (driverId == null || driverId.isEmpty) continue;

        final tripsRes = await _supabase
            .from('trips')
            .select('''
              id,
              status,
              scheduled_departure_at,
              routes (
                id,
                name,
                from_label,
                to_label
              )
            ''')
            .eq('driver_id', driverId)
            .neq('status', 'completado')
            .neq('status', 'cancelado')
            .order('scheduled_departure_at', ascending: true);

        Map<String, dynamic>? selectedTrip;
        for (final rawTrip in tripsRes) {
          final trip = Map<String, dynamic>.from(rawTrip as Map);
          final route = trip['routes'];
          if (route is! Map) continue;
          final routeMap = Map<String, dynamic>.from(route);
          final tripFromLabel = routeMap['from_label']?.toString();
          if (tripFromLabel == fromLabel) {
            selectedTrip = trip;
            break;
          }
        }

        if (selectedTrip == null) continue;

        final tripId = selectedTrip['id']?.toString();
        if (tripId == null || tripId.isEmpty) continue;

        final route = Map<String, dynamic>.from(selectedTrip['routes'] as Map);
        final totalSeats = (driver['capacity'] as int?) ?? 14;
        final reservationsRes = await _supabase
            .from('reservations')
            .select('seats')
            .eq('trip_id', tripId)
            .eq('status', 'activa');

        var occupiedSeats = 0;
        for (final rawReservation in reservationsRes) {
          final reservation = Map<String, dynamic>.from(rawReservation as Map);
          final seats = reservation['seats'];
          if (seats is List) {
            occupiedSeats += seats.length;
          }
        }
        final availableSeats = totalSeats - occupiedSeats;

        if (availableSeats <= 0) continue;

        final profile = driver['profiles'] is Map ? Map<String, dynamic>.from(driver['profiles'] as Map) : null;
        final firstName = profile?['first_name']?.toString().trim() ?? '';
        final lastName = profile?['last_name']?.toString().trim() ?? '';
        final fullName = '$firstName $lastName'.trim();
        final routeName = route['name']?.toString().trim();
        final routeFrom = route['from_label']?.toString().trim() ?? '';
        final routeTo = route['to_label']?.toString().trim() ?? '';

        result.add(ViajeDisponible(
          tripId: tripId,
          driverId: driverId,
          driverName: (profile?['name']?.toString().trim().isNotEmpty ?? false)
              ? profile!['name'].toString().trim()
              : (fullName.isNotEmpty ? fullName : 'Conductor sin nombre'),
          plate: driver['plate']?.toString() ?? 'Sin placa',
          vehicleType: driver['vehicle_type']?.toString() ?? 'Vehiculo',
          totalSeats: totalSeats,
          availableSeats: availableSeats,
          routeLabel: (routeName != null && routeName.isNotEmpty) ? routeName : '$routeFrom → $routeTo',
          rating: (driver['rating_avg'] as num?)?.toDouble() ?? 0.0,
          ratingCount: (driver['rating_count'] as int?) ?? 0,
          direction: direction,
          status: driver['estado']?.toString() ?? '',
        ));
      }

      return result;
    } catch (e) {
      throw Exception('Error al cargar conductores: $e');
    }
  }
}
