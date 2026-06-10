import 'package:supabase_flutter/supabase_flutter.dart';

import '../../reserva/providers/reserva_provider.dart';

/// Viaje disponible para el pasajero (solo datos de Supabase).
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

/// Búsqueda de conductores: solo viajes (`trips`) con `status = esperando` y ruta acorde a la dirección.
class BusquedaService {
  final _supabase = Supabase.instance.client;

  /// [direction] `si_cho` (San Isidro → Chosica) o `cho_si` (Chosica → San Isidro), según `routes.from_label`.
  Future<List<ViajeDisponible>> buscarViajes(String direction) async {
    try {
      final expectedFrom = direction == 'si_cho' ? 'San Isidro' : 'Chosica';

      final tripsRes = await _supabase.from('trips').select('''
            id,
            status,
            driver_id,
            vehicle_id,
            drivers(
              id,
              plate,
              vehicle_type,
              capacity,
              estado,
              cuenta_activa,
              rating_avg,
              rating_count,
              profiles(name, first_name, last_name)
            ),
            vehicles(id, plate, vehicle_type, total_seats),
            routes(name, from_label, to_label)
          ''').eq('status', 'esperando');

      final rawList = (tripsRes as List).cast<Map<String, dynamic>>();
      final result = <ViajeDisponible>[];
      final seenDriverIds = <String>{};

      for (final row in rawList) {
        final route = row['routes'];
        if (route is! Map) continue;
        final routeMap = Map<String, dynamic>.from(route);
        final fromLabel = routeMap['from_label']?.toString().trim();
        if (fromLabel != expectedFrom) continue;

        final drivers = row['drivers'];
        if (drivers is! Map) continue;
        final driverMap = Map<String, dynamic>.from(drivers);

        if ((driverMap['cuenta_activa'] as bool?) == false) continue;
        if ((driverMap['estado']?.toString() ?? '').toLowerCase() == 'inactivo') continue;

        final driverId = driverMap['id']?.toString();
        if (driverId == null || driverId.isEmpty) continue;
        if (seenDriverIds.contains(driverId)) continue;

        final tripId = row['id']?.toString();
        if (tripId == null || tripId.isEmpty) continue;

        var totalSeats = (driverMap['capacity'] as num?)?.toInt() ?? 0;
        final vehicles = row['vehicles'];
        if (vehicles is Map) {
          final v = Map<String, dynamic>.from(vehicles);
          final ts = (v['total_seats'] as num?)?.toInt();
          if (ts != null && ts > 0) totalSeats = ts;
        }
        if (totalSeats <= 0) continue;

        final reservationsRes = await _supabase
            .from('reservations')
            .select('seats')
            .eq('trip_id', tripId)
            .eq('status', 'activa');

        var occupiedSeats = 0;
        for (final rawReservation in reservationsRes as List) {
          final reservation = Map<String, dynamic>.from(rawReservation as Map);
          final seats = reservation['seats'];
          if (seats is List) {
            occupiedSeats += seats.length;
          }
        }
        final availableSeats = totalSeats - occupiedSeats;
        if (availableSeats <= 0) continue;

        seenDriverIds.add(driverId);

        final profile = driverMap['profiles'] is Map ? Map<String, dynamic>.from(driverMap['profiles'] as Map) : null;
        final firstName = profile?['first_name']?.toString().trim() ?? '';
        final lastName = profile?['last_name']?.toString().trim() ?? '';
        final fullName = '$firstName $lastName'.trim();
        final routeName = routeMap['name']?.toString().trim();
        final routeFrom = routeMap['from_label']?.toString().trim() ?? '';
        final routeTo = routeMap['to_label']?.toString().trim() ?? '';

        result.add(
          ViajeDisponible(
            tripId: tripId,
            driverId: driverId,
            driverName: (profile?['name']?.toString().trim().isNotEmpty ?? false)
                ? profile!['name'].toString().trim()
                : (fullName.isNotEmpty ? fullName : 'Conductor'),
            plate: driverMap['plate']?.toString() ?? '',
            vehicleType: driverMap['vehicle_type']?.toString() ?? 'Vehículo',
            totalSeats: totalSeats,
            availableSeats: availableSeats,
            routeLabel: (routeName != null && routeName.isNotEmpty) ? routeName : '$routeFrom → $routeTo',
            rating: (driverMap['rating_avg'] as num?)?.toDouble() ?? 0.0,
            ratingCount: (driverMap['rating_count'] as num?)?.toInt() ?? 0,
            direction: direction,
            status: driverMap['estado']?.toString() ?? (row['status']?.toString() ?? ''),
          ),
        );
      }

      return result;
    } catch (e) {
      throw Exception('Error al cargar conductores: $e');
    }
  }
}
