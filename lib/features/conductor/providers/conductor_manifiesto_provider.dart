import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ManifiestoEstadoPasajero {
  pendiente,
  subio,
  noSubio,
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
  });

  final String id;
  final String nombres;
  final String apellidos;
  final String dni;
  final String telefono;
  final int asiento;
  final String puntoRecojo;
  final ManifiestoEstadoPasajero estado;

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
  });

  final ConductorManifiestoLoadStatus status;
  final DateTime generadoAt;
  final List<ManifiestoItem> passengers;
  final String? tripStatus;
  final String? errorMessage;
}

class ConductorManifiestoController extends StateNotifier<ConductorManifiestoState> {
  ConductorManifiestoController() : super(ConductorManifiestoState.initial()) {
    _load();
  }

  static const _prefsKey = 'sdag_conductor_manifiesto_cache';
  static const _prefsDateKey = 'sdag_conductor_manifiesto_generated_at';

  Future<void> _load() async {
    state = state.copyWith(status: ConductorManifiestoLoadStatus.loading, errorMessage: null);
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    final cachedDate = prefs.getString(_prefsDateKey);

    if (cached != null) {
      final list = _decodeList(cached);
      if (list.isNotEmpty) {
        final date = DateTime.tryParse(cachedDate ?? '');
        state = state.copyWith(
          status: ConductorManifiestoLoadStatus.ready,
          listaPasajeros: list,
          generadoAt: date ?? state.generadoAt,
          offlineCached: true,
          errorMessage: null,
        );
        return;
      }
    }

    final result = await _loadFromSupabase();
    state = state.copyWith(
      status: result.status,
      listaPasajeros: result.passengers,
      generadoAt: result.generadoAt,
      offlineCached: false,
      tripStatus: result.tripStatus,
      errorMessage: result.errorMessage,
    );
    if (result.status == ConductorManifiestoLoadStatus.ready && result.passengers.isNotEmpty) {
      await cachearManifiesto();
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

      final manifest = await Supabase.instance.client
          .from('manifests')
          .select('*, manifest_entries(*, profiles(name, dni, phone))')
          .eq('trip_id', tripId)
          .maybeSingle();

      if (manifest == null) {
        return _ManifestLoadResult(
          status: ConductorManifiestoLoadStatus.noPassengersYet,
          generadoAt: DateTime.now(),
          passengers: const [],
          tripStatus: tripStatus,
          errorMessage: null,
        );
      }

      final generatedAt = DateTime.tryParse(manifest['created_at']?.toString() ?? '') ?? DateTime.now();
      final entriesRaw = manifest['manifest_entries'];
      if (entriesRaw is! List || entriesRaw.isEmpty) {
        return _ManifestLoadResult(
          status: ConductorManifiestoLoadStatus.noPassengersYet,
          generadoAt: generatedAt,
          passengers: const [],
          tripStatus: tripStatus,
          errorMessage: null,
        );
      }

      final out = <ManifiestoItem>[];
      for (var i = 0; i < entriesRaw.length; i++) {
        final e = entriesRaw[i];
        if (e is! Map) continue;
        final entry = e.cast<String, dynamic>();
        final profileRaw = entry['profiles'];
        final profile = (profileRaw is Map<String, dynamic>)
            ? profileRaw
            : (profileRaw is Map ? profileRaw.cast<String, dynamic>() : <String, dynamic>{});

        final fullName = profile['name']?.toString() ?? '';
        final dni = profile['dni']?.toString() ?? '—';
        final phone = profile['phone']?.toString() ?? '—';

        final passengerId =
            entry['profile_id']?.toString() ?? entry['passenger_profile_id']?.toString() ?? '';

        final seatRaw = entry['seat_number'] ?? entry['seat'] ?? entry['asiento'];
        final seat = seatRaw is int ? seatRaw : int.tryParse(seatRaw?.toString() ?? '') ?? (i + 1);

        final pickup = entry['pickup_text']?.toString() ?? entry['pickup_point']?.toString() ?? '—';

        final boarding = entry['boarding'];
        final estado = switch (boarding) {
          true => ManifiestoEstadoPasajero.subio,
          false => ManifiestoEstadoPasajero.noSubio,
          _ => ManifiestoEstadoPasajero.pendiente,
        };

        out.add(
          ManifiestoItem(
            id: passengerId.isEmpty ? 'p_$i' : passengerId,
            nombres: fullName,
            apellidos: '',
            dni: dni,
            telefono: phone,
            asiento: seat,
            puntoRecojo: pickup,
            estado: estado,
          ),
        );
      }

      out.sort((a, b) => a.asiento.compareTo(b.asiento));
      return _ManifestLoadResult(
        status: ConductorManifiestoLoadStatus.ready,
        generadoAt: generatedAt,
        passengers: out,
        tripStatus: tripStatus,
        errorMessage: null,
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
}

final conductorManifiestoProvider =
    StateNotifierProvider<ConductorManifiestoController, ConductorManifiestoState>(
  (ref) => ConductorManifiestoController(),
);
