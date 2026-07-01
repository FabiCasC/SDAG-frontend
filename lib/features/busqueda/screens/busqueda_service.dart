import 'package:supabase_flutter/supabase_flutter.dart';

import '../../reserva/providers/reserva_provider.dart';
import '../utils/busqueda_utils.dart';

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
      if (!isRegisteredRouteDirection(direction)) {
        throw Exception('Dirección de ruta no registrada');
      }

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
        final toLabel = routeMap['to_label']?.toString().trim();
        if (!matchesTripDirection(fromLabel: fromLabel, toLabel: toLabel, direction: direction)) {
          continue;
        }

        final drivers = row['drivers'];
        if (drivers is! Map) continue;
        final driverMap = Map<String, dynamic>.from(drivers);

        if (!isDriverEligibleForListing(
          cuentaActiva: driverMap['cuenta_activa'] as bool?,
          estado: driverMap['estado']?.toString(),
        )) continue;

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
            .inFilter('status', ['activa', 'completada']);

        var occupiedSeats = countOccupiedSeatsFromReservationRows(reservationsRes as List);
        final availableSeats = availableSeatsCount(
          totalSeats: totalSeats,
          occupiedSeats: occupiedSeats,
        );
        if (availableSeats <= 0) continue;

        seenDriverIds.add(driverId);

        final profile = driverMap['profiles'] is Map ? Map<String, dynamic>.from(driverMap['profiles'] as Map) : null;
        final firstName = profile?['first_name']?.toString().trim() ?? '';
        final lastName = profile?['last_name']?.toString().trim() ?? '';
        final fullName = '$firstName $lastName'.trim();
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
            routeLabel: buildRouteLabel(
              name: routeMap['name']?.toString(),
              from: routeFrom,
              to: routeTo,
            ),
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
