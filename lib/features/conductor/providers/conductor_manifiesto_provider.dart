import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ManifiestoEstadoPasajero {
  pendiente,
  subio,
  noSubio,
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
    required this.generadoAt,
    required this.listaPasajeros,
    required this.offlineCached,
  });

  final DateTime generadoAt;
  final List<ManifiestoItem> listaPasajeros;
  final bool offlineCached;

  int get total => listaPasajeros.length;
  int get abordaron =>
      listaPasajeros.where((p) => p.estado == ManifiestoEstadoPasajero.subio).length;
  int get noAbordaron =>
      listaPasajeros.where((p) => p.estado == ManifiestoEstadoPasajero.noSubio).length;
  int get pendientes =>
      listaPasajeros.where((p) => p.estado == ManifiestoEstadoPasajero.pendiente).length;

  ConductorManifiestoState copyWith({
    DateTime? generadoAt,
    List<ManifiestoItem>? listaPasajeros,
    bool? offlineCached,
  }) {
    return ConductorManifiestoState(
      generadoAt: generadoAt ?? this.generadoAt,
      listaPasajeros: listaPasajeros ?? this.listaPasajeros,
      offlineCached: offlineCached ?? this.offlineCached,
    );
  }

  static ConductorManifiestoState initial() => ConductorManifiestoState(
        generadoAt: DateTime.now(),
        listaPasajeros: const [],
        offlineCached: false,
      );
}

class ConductorManifiestoController extends StateNotifier<ConductorManifiestoState> {
  ConductorManifiestoController() : super(ConductorManifiestoState.initial()) {
    _load();
  }

  static const _prefsKey = 'sdag_conductor_manifiesto_cache';
  static const _prefsDateKey = 'sdag_conductor_manifiesto_generated_at';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    final cachedDate = prefs.getString(_prefsDateKey);

    if (cached != null) {
      final list = _decodeList(cached);
      if (list.isNotEmpty) {
        final date = DateTime.tryParse(cachedDate ?? '');
        state = state.copyWith(
          listaPasajeros: list,
          generadoAt: date ?? state.generadoAt,
          offlineCached: true,
        );
        return;
      }
    }

    final fromSupabase = await _loadFromSupabase();
    state = state.copyWith(
      listaPasajeros: fromSupabase,
      generadoAt: DateTime.now(),
      offlineCached: false,
    );
    if (fromSupabase.isNotEmpty) {
      await cachearManifiesto();
    }
  }

  Future<List<ManifiestoItem>> _loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const [];

    try {
      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();
      final driverId = driver?['id']?.toString();
      if (driverId == null) return const [];

      final trip = await Supabase.instance.client
          .from('trips')
          .select('id')
          .eq('driver_id', driverId)
          .neq('status', 'completado')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final tripId = trip?['id']?.toString();
      if (tripId == null) return const [];

      final reservations = await Supabase.instance.client
          .from('reservations')
          .select('passenger_profile_id, pickup_point, seats')
          .eq('trip_id', tripId)
          .eq('status', 'activa');

      final out = <ManifiestoItem>[];
      for (final rm in (reservations as List).cast<Map<String, dynamic>>()) {
        final passengerId = rm['passenger_profile_id']?.toString();
        final pickup = rm['pickup_point']?.toString() ?? '—';
        final seats = rm['seats'];
          if (passengerId == null || seats is! List) continue;

          final profile = await Supabase.instance.client
              .from('profiles')
              .select('first_name, last_name, dni, phone')
              .eq('id', passengerId)
              .maybeSingle();
          final nombres = profile?['first_name']?.toString() ?? '';
          final apellidos = profile?['last_name']?.toString() ?? '';
          final dni = profile?['dni']?.toString() ?? '—';
          final telefono = profile?['phone']?.toString() ?? '—';

          for (final s in seats) {
            if (s is! int) continue;
            out.add(
              ManifiestoItem(
                id: passengerId,
                nombres: nombres,
                apellidos: apellidos,
                dni: dni,
                telefono: telefono,
                asiento: s,
                puntoRecojo: pickup,
                estado: ManifiestoEstadoPasajero.pendiente,
              ),
            );
          }
      }

      out.sort((a, b) => a.asiento.compareTo(b.asiento));
      return out;
    } catch (_) {
      return const [];
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
