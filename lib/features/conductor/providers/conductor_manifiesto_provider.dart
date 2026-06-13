import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ManifiestoEstadoPasajero {
  pendiente,
  subio,
  noSubio,
  cancelado,
}

enum ConductorManifiestoLoadStatus {
  loading,
  ready,
  noActiveTrip,
  noPassengersYet,
  error,
}

class ManifiestoItem {
  const ManifiestoItem({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.telefono,
    required this.asiento,
    required this.puntoRecojo,
    required this.estado,
    required this.reservationStatus,
  });

  final String id;
  final String nombres;
  final String apellidos;
  final String dni;
  final String telefono;
  final int asiento;
  final String puntoRecojo;
  final ManifiestoEstadoPasajero estado;
  final String reservationStatus;

  String get nombreCompleto => '$nombres $apellidos'.trim();

  ManifiestoItem copyWith({
    String? id,
    String? nombres,
    String? apellidos,
    String? dni,
    String? telefono,
    int? asiento,
    String? puntoRecojo,
    ManifiestoEstadoPasajero? estado,
    String? reservationStatus,
  }) {
    return ManifiestoItem(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      asiento: asiento ?? this.asiento,
      puntoRecojo: puntoRecojo ?? this.puntoRecojo,
      estado: estado ?? this.estado,
      reservationStatus: reservationStatus ?? this.reservationStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'dni': dni,
      'telefono': telefono,
      'asiento': asiento,
      'puntoRecojo': puntoRecojo,
      'estado': estado.name,
      'reservationStatus': reservationStatus,
    };
  }

  static ManifiestoItem? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final nombres = json['nombres'] as String?;
    final apellidos = json['apellidos'] as String?;
    final dni = json['dni'] as String?;
    final telefono = json['telefono'] as String?;
    final asiento = json['asiento'];
    final puntoRecojo = json['puntoRecojo'] as String?;
    final estadoRaw = json['estado'] as String?;
    final reservationStatus = json['reservationStatus'] as String? ?? 'activa';
    if (id == null ||
        nombres == null ||
        apellidos == null ||
        dni == null ||
        telefono == null ||
        asiento is! int ||
        puntoRecojo == null ||
        estadoRaw == null) {
      return null;
    }
    final estado = ManifiestoEstadoPasajero.values
        .where((e) => e.name == estadoRaw)
        .cast<ManifiestoEstadoPasajero?>()
        .firstWhere((e) => e != null, orElse: () => null);
    if (estado == null) return null;
    return ManifiestoItem(
      id: id,
      nombres: nombres,
      apellidos: apellidos,
      dni: dni,
      telefono: telefono,
      asiento: asiento,
      puntoRecojo: puntoRecojo,
      estado: estado,
      reservationStatus: reservationStatus,
    );
  }
}

class ConductorManifiestoState {
  const ConductorManifiestoState({
    required this.status,
    required this.generadoAt,
    required this.listaPasajeros,
    required this.offlineCached,
    required this.tripStatus,
    required this.errorMessage,
  });

  final ConductorManifiestoLoadStatus status;
  final DateTime generadoAt;
  final List<ManifiestoItem> listaPasajeros;
  final bool offlineCached;
  final String? tripStatus;
  final String? errorMessage;

  int get total => listaPasajeros.length;
  int get abordaron =>
      listaPasajeros.where((p) => p.estado == ManifiestoEstadoPasajero.subio).length;
  int get noAbordaron =>
      listaPasajeros.where((p) => p.estado == ManifiestoEstadoPasajero.noSubio).length;
  int get pendientes =>
      listaPasajeros.where((p) => p.estado == ManifiestoEstadoPasajero.pendiente).length;

  ConductorManifiestoState copyWith({
    ConductorManifiestoLoadStatus? status,
    DateTime? generadoAt,
    List<ManifiestoItem>? listaPasajeros,
    bool? offlineCached,
    String? tripStatus,
    String? errorMessage,
  }) {
    return ConductorManifiestoState(
      status: status ?? this.status,
      generadoAt: generadoAt ?? this.generadoAt,
      listaPasajeros: listaPasajeros ?? this.listaPasajeros,
      offlineCached: offlineCached ?? this.offlineCached,
      tripStatus: tripStatus ?? this.tripStatus,
      errorMessage: errorMessage,
    );
  }

  static ConductorManifiestoState initial() => ConductorManifiestoState(
        status: ConductorManifiestoLoadStatus.loading,
        generadoAt: DateTime.now(),
        listaPasajeros: const [],
        offlineCached: false,
        tripStatus: null,
        errorMessage: null,
      );
}

class _ManifestLoadResult {
  const _ManifestLoadResult({
    required this.status,
    required this.generadoAt,
    required this.passengers,
    required this.tripStatus,
    required this.errorMessage,
    this.tripId,
    this.manifestId,
  });

  final ConductorManifiestoLoadStatus status;
  final DateTime generadoAt;
  final List<ManifiestoItem> passengers;
  final String? tripStatus;
  final String? errorMessage;
  final String? tripId;
  final String? manifestId;
}

class ConductorManifiestoController extends StateNotifier<ConductorManifiestoState> {
  ConductorManifiestoController() : super(ConductorManifiestoState.initial()) {
    reload();
  }

  static const _prefsKey = 'sdag_conductor_manifiesto_cache';
  static const _prefsDateKey = 'sdag_conductor_manifiesto_generated_at';

  StreamSubscription<List<Map<String, dynamic>>>? _entriesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _reservationsSub;
  String? _subscribedManifestId;
  String? _subscribedTripId;

  Future<void> reload() => _cargarManifiesto();

  Future<void> _cargarManifiesto({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(
        status: ConductorManifiestoLoadStatus.loading,
        errorMessage: null,
        offlineCached: false,
      );
    }

    try {
      final result = await _loadFromSupabase();
      state = state.copyWith(
        status: result.status,
        listaPasajeros: result.passengers,
        generadoAt: result.generadoAt,
        offlineCached: false,
        tripStatus: result.tripStatus,
        errorMessage: result.errorMessage,
      );
      _setupRealtime(tripId: result.tripId, manifestId: result.manifestId);
      if (result.status == ConductorManifiestoLoadStatus.ready && result.passengers.isNotEmpty) {
        await cachearManifiesto();
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefsKey);
      final cachedDate = prefs.getString(_prefsDateKey);
      final list = cached == null ? const <ManifiestoItem>[] : _decodeList(cached);
      if (list.isNotEmpty) {
        final date = DateTime.tryParse(cachedDate ?? '');
        state = state.copyWith(
          status: ConductorManifiestoLoadStatus.ready,
          listaPasajeros: list,
          generadoAt: date ?? DateTime.now(),
          offlineCached: true,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: ConductorManifiestoLoadStatus.error,
          errorMessage: 'No se pudo cargar el manifiesto: $e',
        );
      }
    }
  }

  void _setupRealtime({String? tripId, String? manifestId}) {
    if (manifestId != null && manifestId != _subscribedManifestId) {
      _entriesSub?.cancel();
      _subscribedManifestId = manifestId;
      _entriesSub = Supabase.instance.client
          .from('manifest_entries')
          .stream(primaryKey: ['id'])
          .eq('manifest_id', manifestId)
          .listen((_) => _cargarManifiesto(silent: true));
    } else if (manifestId == null) {
      _entriesSub?.cancel();
      _subscribedManifestId = null;
    }

    if (tripId != null && tripId != _subscribedTripId) {
      _reservationsSub?.cancel();
      _subscribedTripId = tripId;
      _reservationsSub = Supabase.instance.client
          .from('reservations')
          .stream(primaryKey: ['id'])
          .eq('trip_id', tripId)
          .listen((_) => _cargarManifiesto(silent: true));
    } else if (tripId == null) {
      _reservationsSub?.cancel();
      _subscribedTripId = null;
    }
  }

  Future<_ManifestLoadResult> _loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return _ManifestLoadResult(
        status: ConductorManifiestoLoadStatus.error,
        generadoAt: DateTime.now(),
        passengers: const [],
        tripStatus: null,
        errorMessage: 'No hay una sesión activa.',
      );
    }

    try {
      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('profile_id', user.id)
          .single();
      final driverId = driver['id']?.toString();
      if (driverId == null || driverId.isEmpty) {
        return _ManifestLoadResult(
          status: ConductorManifiestoLoadStatus.error,
          generadoAt: DateTime.now(),
          passengers: const [],
          tripStatus: null,
          errorMessage: 'No se encontró el conductor asociado a esta cuenta.',
        );
      }

      final trip = await Supabase.instance.client
          .from('trips')
          .select('id, status')
          .eq('driver_id', driverId)
          .inFilter('status', ['esperando', 'en_ruta'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final tripId = trip?['id']?.toString();
      final tripStatus = trip?['status']?.toString();

      if (tripId == null || tripId.isEmpty) {
        return _ManifestLoadResult(
          status: ConductorManifiestoLoadStatus.noActiveTrip,
          generadoAt: DateTime.now(),
          passengers: const [],
          tripStatus: tripStatus,
          errorMessage: null,
        );
      }

      final reservasRaw = await Supabase.instance.client
          .from('reservations')
          .select('''
            id, seats, pickup_point, status, passenger_profile_id,
            profiles:passenger_profile_id(name, first_name, last_name, dni, phone)
          ''')
          .eq('trip_id', tripId)
          .inFilter('status', ['activa', 'completada', 'cancelada'])
          .order('created_at');

      final reservas = (reservasRaw as List).cast<Map<String, dynamic>>();
      if (reservas.isEmpty) {
        return _ManifestLoadResult(
          status: ConductorManifiestoLoadStatus.noPassengersYet,
          generadoAt: DateTime.now(),
          passengers: const [],
          tripStatus: tripStatus,
          errorMessage: null,
          tripId: tripId,
        );
      }

      final manifest = await Supabase.instance.client
          .from('manifests')
          .select('id, created_at')
          .eq('trip_id', tripId)
          .maybeSingle();

      final manifestId = manifest?['id']?.toString();
      final generatedAt =
          DateTime.tryParse(manifest?['created_at']?.toString() ?? '') ?? DateTime.now();

      final manifestEntries = manifestId == null
          ? const <Map<String, dynamic>>[]
          : ((await Supabase.instance.client
                  .from('manifest_entries')
                  .select('reservation_id, seat_number, boarding_status')
                  .eq('manifest_id', manifestId)) as List)
              .cast<Map<String, dynamic>>();

      final out = <ManifiestoItem>[];
      for (var i = 0; i < reservas.length; i++) {
        final reserva = reservas[i];
        final reservationId = reserva['id']?.toString() ?? '';
        final profileRaw = reserva['profiles'];
        final profile = profileRaw is Map<String, dynamic>
            ? profileRaw
            : profileRaw is Map
                ? profileRaw.cast<String, dynamic>()
                : <String, dynamic>{};

        final name = profile['name']?.toString().trim() ?? '';
        final firstName = profile['first_name']?.toString().trim() ?? '';
        final lastName = profile['last_name']?.toString().trim() ?? '';
        final nombres = firstName.isNotEmpty ? firstName : name;
        final apellidos = lastName;
        final dni = profile['dni']?.toString().trim();
        final phone = profile['phone']?.toString().trim();
        final pickup = reserva['pickup_point']?.toString().trim() ?? '—';
        final reservationStatus = reserva['status']?.toString() ?? 'activa';
        final passengerId = profile['id']?.toString() ??
            reserva['passenger_profile_id']?.toString() ??
            reservationId;

        final seats = _parseSeats(reserva['seats']);
        final seatList = seats.isEmpty ? [i + 1] : seats;

        for (final seat in seatList) {
          Map<String, dynamic>? entry;
          for (final e in manifestEntries) {
            if (e['reservation_id']?.toString() != reservationId) continue;
            final entrySeat = e['seat_number'];
            final seatNum =
                entrySeat is int ? entrySeat : int.tryParse(entrySeat?.toString() ?? '');
            if (seatNum == null || seatNum == seat) {
              entry = e;
              break;
            }
          }

          final boarding = entry?['boarding_status'] ?? 'pendiente';

          out.add(
            ManifiestoItem(
              id: passengerId.isEmpty ? 'p_${reservationId}_$seat' : passengerId,
              nombres: nombres.isEmpty ? 'Pasajero' : nombres,
              apellidos: apellidos,
              dni: (dni == null || dni.isEmpty) ? '—' : dni,
              telefono: (phone == null || phone.isEmpty) ? '—' : phone,
              asiento: seat,
              puntoRecojo: pickup,
              estado: _resolveEstado(
                reservationStatus: reservationStatus,
                boarding: boarding,
              ),
              reservationStatus: reservationStatus,
            ),
          );
        }
      }

      out.sort((a, b) => a.asiento.compareTo(b.asiento));

      return _ManifestLoadResult(
        status: ConductorManifiestoLoadStatus.ready,
        generadoAt: generatedAt,
        passengers: out,
        tripStatus: tripStatus,
        errorMessage: null,
        tripId: tripId,
        manifestId: manifestId,
      );
    } catch (e) {
      return _ManifestLoadResult(
        status: ConductorManifiestoLoadStatus.error,
        generadoAt: DateTime.now(),
        passengers: const [],
        tripStatus: null,
        errorMessage: 'No se pudo cargar el manifiesto: $e',
      );
    }
  }

  List<int> _parseSeats(dynamic rawSeats) {
    if (rawSeats is! List) return const [];
    final out = <int>[];
    for (final seat in rawSeats) {
      if (seat is int) {
        out.add(seat);
      } else if (seat is num) {
        out.add(seat.toInt());
      } else {
        final parsed = int.tryParse(seat.toString());
        if (parsed != null) out.add(parsed);
      }
    }
    out.sort();
    return out;
  }

  ManifiestoEstadoPasajero _resolveEstado({
    required String reservationStatus,
    required dynamic boarding,
  }) {
    if (reservationStatus == 'cancelada') return ManifiestoEstadoPasajero.cancelado;
    if (reservationStatus == 'completada') return ManifiestoEstadoPasajero.subio;

    final value = boarding?.toString() ?? '';
    return switch (value) {
      'abordo' => ManifiestoEstadoPasajero.subio,
      'no_abordo' => ManifiestoEstadoPasajero.noSubio,
      'cancelado' => ManifiestoEstadoPasajero.cancelado,
      _ => ManifiestoEstadoPasajero.pendiente,
    };
  }

  List<ManifiestoItem> _decodeList(String jsonStr) {
    try {
      final raw = jsonDecode(jsonStr);
      if (raw is! List) return const [];
      final out = <ManifiestoItem>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final v = ManifiestoItem.fromJson(item);
          if (v != null) out.add(v);
        } else if (item is Map) {
          final v = ManifiestoItem.fromJson(item.cast<String, dynamic>());
          if (v != null) out.add(v);
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> marcarAbordaje(String passengerId) async {
    state = state.copyWith(
      listaPasajeros: [
        for (final p in state.listaPasajeros)
          if (p.id == passengerId) p.copyWith(estado: ManifiestoEstadoPasajero.subio) else p,
      ],
    );
    await cachearManifiesto();
  }

  Future<void> marcarAusencia(String passengerId) async {
    state = state.copyWith(
      listaPasajeros: [
        for (final p in state.listaPasajeros)
          if (p.id == passengerId) p.copyWith(estado: ManifiestoEstadoPasajero.noSubio) else p,
      ],
    );
    await cachearManifiesto();
  }

  Future<void> revertirAusencia(String passengerId) async {
    state = state.copyWith(
      listaPasajeros: [
        for (final p in state.listaPasajeros)
          if (p.id == passengerId) p.copyWith(estado: ManifiestoEstadoPasajero.pendiente) else p,
      ],
    );
    await cachearManifiesto();
  }

  Future<void> cachearManifiesto() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.listaPasajeros.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, jsonStr);
    await prefs.setString(_prefsDateKey, state.generadoAt.toIso8601String());
  }

  @override
  void dispose() {
    _entriesSub?.cancel();
    _reservationsSub?.cancel();
    super.dispose();
  }
}

final conductorManifiestoProvider =
    StateNotifierProvider<ConductorManifiestoController, ConductorManifiestoState>(
  (ref) => ConductorManifiestoController(),
);
