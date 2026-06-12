import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const _googleMapsApiKey = 'AIzaSyBspcTEh828O90o862FewdtQeCek9MIXOk';
const _validRouteA = 'San Isidro → Chosica';
const _validRouteB = 'Chosica → San Isidro';
const _chosicaTerminal = LatLng(-11.9375, -76.6934);
const _sanIsidroTerminal = LatLng(-12.0977, -77.0365);

enum AdminVehiculoEstado {
  disponible,
  enRuta,
}

enum AdminViajeRutaFiltro {
  todos,
  sanIsidroChosica,
  chosicaSanIsidro,
}

class AdminVehiculoActivo {
  const AdminVehiculoActivo({
    required this.conductorId,
    required this.driverId,
    required this.conductorNombre,
    required this.telefono,
    required this.placa,
    required this.vehicleType,
    required this.estado,
    required this.posicion,
    required this.rutaLabel,
    required this.ocupados,
    required this.capacidad,
    required this.etaMinutos,
  });

  final String conductorId;
  final String driverId;
  final String conductorNombre;
  final String? telefono;
  final String placa;
  final String? vehicleType;
  final AdminVehiculoEstado estado;
  final LatLng? posicion;
  final String? rutaLabel;
  final int ocupados;
  final int capacidad;
  final int? etaMinutos;

  bool get tieneViajeActivo => rutaLabel != null && rutaLabel!.isNotEmpty;
}

class AdminMonitoreoState {
  const AdminMonitoreoState({
    required this.vehiculosActivos,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<AdminVehiculoActivo> vehiculosActivos;
  final bool isLoading;
  final String? errorMessage;

  AdminMonitoreoState copyWith({
    List<AdminVehiculoActivo>? vehiculosActivos,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminMonitoreoState(
      vehiculosActivos: vehiculosActivos ?? this.vehiculosActivos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  static AdminMonitoreoState initial() => const AdminMonitoreoState(
        vehiculosActivos: [],
        isLoading: true,
        errorMessage: null,
      );
}

class AdminMonitoreoController extends StateNotifier<AdminMonitoreoState> {
  AdminMonitoreoController({required this.ref}) : super(AdminMonitoreoState.initial()) {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh(silent: true));
    ref.onDispose(() {
      _timer?.cancel();
    });
  }

  final Ref ref;
  Timer? _timer;

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final drivers = await Supabase.instance.client
          .from('drivers')
          .select('''
            id, profile_id, plate, vehicle_type, capacity, estado, rating_avg,
            profiles(name, phone),
            trips(id, status, route_id, started_at,
              routes(name, from_label, to_label))
          ''')
          .eq('cuenta_activa', true)
          .neq('estado', 'inactivo');

      final driverRows = (drivers as List).cast<Map<String, dynamic>>();
      final enRutaIds = driverRows
          .where((d) => _isEnRuta(d['estado']?.toString()))
          .map((d) => d['id']?.toString())
          .whereType<String>()
          .toList(growable: false);

      final locationsByDriver = <String, Map<String, dynamic>>{};
      if (enRutaIds.isNotEmpty) {
        final locations = await Supabase.instance.client
            .from('driver_locations')
            .select('lat, lng, driver_id, occupied_seats, trip_id, drivers(profiles(name), plate)')
            .inFilter('driver_id', enRutaIds);

        for (final loc in (locations as List).cast<Map<String, dynamic>>()) {
          final driverId = loc['driver_id']?.toString();
          if (driverId != null && driverId.isNotEmpty) {
            locationsByDriver[driverId] = loc;
          }
        }
      }

      final items = await Future.wait(
        driverRows.map((row) => _mapDriverRow(row, locationsByDriver: locationsByDriver)),
      );

      items.sort((a, b) => a.conductorNombre.toLowerCase().compareTo(b.conductorNombre.toLowerCase()));

      state = state.copyWith(
        vehiculosActivos: items,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '$error',
      );
    }
  }

  Future<AdminVehiculoActivo> _mapDriverRow(
    Map<String, dynamic> row, {
    Map<String, Map<String, dynamic>> locationsByDriver = const {},
  }) async {
    final driverId = row['id']?.toString() ?? '';
    final conductorId = row['profile_id']?.toString() ?? driverId;
    final profile = _asMap(row['profiles']);
    final conductorNombre = profile?['name']?.toString().trim().isNotEmpty == true
        ? profile!['name'].toString().trim()
        : 'Conductor';

    final location = locationsByDriver[driverId];
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    final posicion = (lat != null && lng != null) ? LatLng(lat, lng) : null;

    final trip = _pickActiveTrip(row['trips'], preferredTripId: location?['trip_id']?.toString());
    final rutaLabel = _tripRouteLabel(trip);
    final etaMinutos = posicion != null && rutaLabel != null
        ? await _fetchEtaMinutes(posicion, rutaLabel)
        : null;

    return AdminVehiculoActivo(
      conductorId: conductorId,
      driverId: driverId,
      conductorNombre: conductorNombre,
      telefono: profile?['phone']?.toString(),
      placa: row['plate']?.toString() ?? 'Sin placa',
      vehicleType: row['vehicle_type']?.toString(),
      estado: _mapEstado(row['estado']?.toString()),
      posicion: posicion,
      rutaLabel: rutaLabel,
      ocupados: (location?['occupied_seats'] as num?)?.toInt() ?? 0,
      capacidad: (row['capacity'] as num?)?.toInt() ?? 0,
      etaMinutos: etaMinutos,
    );
  }

  bool _isEnRuta(String? estado) => estado == 'en_ruta' || estado == 'enRuta';

  AdminVehiculoEstado _mapEstado(String? estado) {
    return _isEnRuta(estado) ? AdminVehiculoEstado.enRuta : AdminVehiculoEstado.disponible;
  }

  Map<String, dynamic>? _pickActiveTrip(dynamic rawTrips, {String? preferredTripId}) {
    final trips = _asList(rawTrips)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (trips.isEmpty) return null;

    bool isActive(Map<String, dynamic> trip) {
      final status = trip['status']?.toString();
      return status == 'en_ruta';
    }

    if (preferredTripId != null && preferredTripId.isNotEmpty) {
      for (final trip in trips) {
        if (trip['id']?.toString() == preferredTripId && isActive(trip)) {
          return trip;
        }
      }
    }

    final activeTrips = trips.where(isActive).toList(growable: false);
    if (activeTrips.isEmpty) return null;
    activeTrips.sort((a, b) {
      final aDate = DateTime.tryParse(a['started_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['started_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return activeTrips.first;
  }

  String? _tripRouteLabel(Map<String, dynamic>? trip) {
    if (trip == null) return null;
    final route = _asMap(trip['routes']);
    final from = route?['from_label']?.toString().trim() ?? '';
    final to = route?['to_label']?.toString().trim() ?? '';
    final name = route?['name']?.toString().trim() ?? '';

    final combined = (from.isNotEmpty && to.isNotEmpty) ? '$from → $to' : name;
    if (combined == _validRouteA || combined == _validRouteB) {
      return combined;
    }
    return null;
  }

  Future<int?> _fetchEtaMinutes(LatLng origin, String routeLabel) async {
    final destination = switch (routeLabel) {
      _validRouteA => _chosicaTerminal,
      _validRouteB => _sanIsidroTerminal,
      _ => null,
    };
    if (destination == null) return null;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&key=$_googleMapsApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final legs = (routes.first as Map<String, dynamic>)['legs'] as List?;
      if (legs == null || legs.isEmpty) return null;
      final duration = (legs.first as Map<String, dynamic>)['duration'] as Map<String, dynamic>?;
      final durationSeconds = (duration?['value'] as num?)?.toInt();
      if (durationSeconds == null) return null;
      return (durationSeconds / 60).round();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    if (value == null) return const [];
    return [value];
  }

}

final adminMonitoreoProvider = StateNotifierProvider<AdminMonitoreoController, AdminMonitoreoState>(
  (ref) => AdminMonitoreoController(ref: ref),
);
