import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanionData {
  final String fullName;
  CompanionData(this.fullName);
}

class DriverReservationRecord {
  final String id;
  final String passengerName;
  final String origin;
  final String destination;
  final DateTime date;
  final List<CompanionData> companions;
  final String status;

  DriverReservationRecord({
    required this.id,
    required this.passengerName,
    required this.origin,
    required this.destination,
    required this.date,
    required this.companions,
    required this.status,
  });
}

class ConductorReservasState {
  final bool loading;
  final List<DriverReservationRecord> reservations;
  final String? error;
  final bool showNewReservationAlert;

  ConductorReservasState({
    required this.loading,
    required this.reservations,
    this.error,
    this.showNewReservationAlert = false,
  });

  ConductorReservasState copyWith({
    bool? loading,
    List<DriverReservationRecord>? reservations,
    String? error,
    bool? showNewReservationAlert,
  }) {
    return ConductorReservasState(
      loading: loading ?? this.loading,
      reservations: reservations ?? this.reservations,
      error: error,
      showNewReservationAlert: showNewReservationAlert ?? this.showNewReservationAlert,
    );
  }
}

class ConductorReservasNotifier extends StateNotifier<ConductorReservasState> {
  ConductorReservasNotifier() : super(ConductorReservasState(loading: true, reservations: [])) {
    _init();
  }

  StreamSubscription? _streamSub;
  List<String> _myTripIds = [];
  int _lastReservationCount = 0;

  Future<void> _init() async {
    await loadReservations();
    _listenToReservations();
  }

  Future<void> loadReservations() async {
    try {
      state = state.copyWith(loading: true, error: null);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(loading: false, error: 'No autorizado');
        return;
      }

      final driverRecord = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (driverRecord == null) {
        state = state.copyWith(loading: false, error: 'Perfil de conductor no encontrado');
        return;
      }
      final driverId = driverRecord['id'];

      // Fetch trips to know which trip_ids belong to this driver (for the stream filter)
      final tripsData = await Supabase.instance.client
          .from('trips')
          .select('id')
          .eq('driver_id', driverId);
      _myTripIds = (tripsData as List).map((t) => t['id'].toString()).toList();

      final response = await Supabase.instance.client
          .from('reservations')
          .select('''
            id,
            created_at,
            pickup_point,
            status,
            passenger:profiles!reservations_passenger_profile_id_fkey(name, first_name, last_name),
            companions:reservation_companions(full_name),
            trips!inner(
              driver_id,
              scheduled_departure_at,
              routes(from_label, to_label)
            )
          ''')
          .eq('trips.driver_id', driverId)
          .order('created_at', ascending: false);

      final List<DriverReservationRecord> loaded = [];
      for (final row in response as List) {
        final pax = row['passenger'] ?? {};
        final name = pax['first_name'] != null && pax['last_name'] != null 
            ? '${pax['first_name']} ${pax['last_name']}'
            : (pax['name'] ?? 'Pasajero');
            
        final trips = row['trips'] ?? {};
        final routes = trips['routes'] ?? {};
        
        final comps = (row['companions'] as List?)?.map((c) => CompanionData(c['full_name'] ?? '')).toList() ?? [];
        
        loaded.add(DriverReservationRecord(
          id: row['id'],
          passengerName: name,
          origin: row['pickup_point'] ?? routes['from_label'] ?? 'Origen',
          destination: routes['to_label'] ?? 'Destino',
          date: DateTime.parse(trips['scheduled_departure_at'] ?? row['created_at']),
          companions: comps,
          status: row['status'] ?? 'activa',
        ));
      }

      _lastReservationCount = loaded.length;
      state = state.copyWith(loading: false, reservations: loaded);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void _listenToReservations() {
    _streamSub = Supabase.instance.client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .listen((data) {
          
      // Filtrar reservaciones que pertenezcan a los viajes del conductor
      final myReservations = data.where((r) => _myTripIds.contains(r['trip_id'].toString())).toList();
      
      if (myReservations.length > _lastReservationCount && _lastReservationCount > 0) {
        // Nueva reserva detectada!
        state = state.copyWith(showNewReservationAlert: true);
        loadReservations(); // Recargar datos enriquecidos (joins)
      } else if (myReservations.length == _lastReservationCount) {
         // Puede ser un update, recargamos silenciosamente
         loadReservations();
      }
      _lastReservationCount = myReservations.length;
    });
  }

  void clearAlert() {
    state = state.copyWith(showNewReservationAlert: false);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

final conductorReservasProvider = StateNotifierProvider<ConductorReservasNotifier, ConductorReservasState>(
  (ref) => ConductorReservasNotifier(),
);
