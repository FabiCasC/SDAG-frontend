// lib/features/viaje/providers/viaje_provider.dart
//
// Reemplaza la versión 100% mock.
// Fuente de datos real: tabla driver_locations (ubicación + ETA del conductor)
// leída desde Supabase cada vez que se llama a refreshFromSupabase().
// El estado de la UI (status, finished, etc.) lo controla el controller igual
// que antes, pero la posición y ETA provienen de Supabase, no de hardcode.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Modelos ────────────────────────────────────────────────────────────────

class ViajeMessage {
  const ViajeMessage({
    required this.id,
    required this.isDriver,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final bool isDriver;
  final String text;
  final DateTime timestamp;
}

enum ViajeStatus {
  esperandoConductor,
  conductorEnCamino,
  enRuta,
}

class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

class ViajeState {
  const ViajeState({
    required this.status,
    required this.etaMinutes,
    required this.showArrivalBanner,
    required this.driverPosition,
    required this.messages,
    required this.readOnlyChat,
    required this.showAlternativePickup,
    required this.alternativePickupText,
    required this.finished,
    required this.locationError,
  });

  final ViajeStatus status;
  final int etaMinutes;
  final bool showArrivalBanner;

  /// Posición real del conductor leída de driver_locations.
  /// null = aún no disponible o error de lectura.
  final GeoPoint? driverPosition;

  final List<ViajeMessage> messages;
  final bool readOnlyChat;
  final bool showAlternativePickup;
  final String? alternativePickupText;
  final bool finished;

  /// Mensaje de error de la última lectura de Supabase (null = sin error).
  final String? locationError;

  ViajeState copyWith({
    ViajeStatus? status,
    int? etaMinutes,
    bool? showArrivalBanner,
    GeoPoint? driverPosition,
    bool clearDriverPosition = false,
    List<ViajeMessage>? messages,
    bool? readOnlyChat,
    bool? showAlternativePickup,
    String? alternativePickupText,
    bool? finished,
    String? locationError,
    bool clearLocationError = false,
  }) {
    return ViajeState(
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      showArrivalBanner: showArrivalBanner ?? this.showArrivalBanner,
      driverPosition:
      clearDriverPosition ? null : (driverPosition ?? this.driverPosition),
      messages: messages ?? this.messages,
      readOnlyChat: readOnlyChat ?? this.readOnlyChat,
      showAlternativePickup:
      showAlternativePickup ?? this.showAlternativePickup,
      alternativePickupText:
      alternativePickupText ?? this.alternativePickupText,
      finished: finished ?? this.finished,
      locationError:
      clearLocationError ? null : (locationError ?? this.locationError),
    );
  }

  static ViajeState initial() {
    return const ViajeState(
      status: ViajeStatus.esperandoConductor,
      etaMinutes: 0,
      showArrivalBanner: false,
      driverPosition: null,
      messages: [],
      readOnlyChat: false,
      showAlternativePickup: false,
      alternativePickupText: null,
      finished: false,
      locationError: null,
    );
  }
}

// ─── Controller ─────────────────────────────────────────────────────────────

class ViajeController extends StateNotifier<ViajeState> {
  ViajeController() : super(ViajeState.initial());

  Timer? _etaTimer;
  Timer? _locationTimer;
  bool _started = false;
  String? _currentDriverId;

  /// Iniciar el ciclo de polling. Llamar con el driver_id de la reserva activa.
  void start(String driverId) {
    if (_started && _currentDriverId == driverId) return;
    _started = true;
    _currentDriverId = driverId;

    // Primera carga inmediata
    refreshFromSupabase(driverId);

    // Poll de ubicación cada 15 s
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 15),
          (_) => refreshFromSupabase(driverId, silent: true),
    );

    // Decremento local de ETA cada 60 s (suaviza la UI entre polls)
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (state.finished) return;
      final next = (state.etaMinutes - 1).clamp(0, 999);
      final banner = next <= 2 && next > 0;
      state = state.copyWith(etaMinutes: next, showArrivalBanner: banner);
    });
  }

  /// Lee driver_locations desde Supabase y actualiza el estado.
  Future<void> refreshFromSupabase(String driverId, {bool silent = false}) async {
    if (state.finished) return;
    try {
      final row = await Supabase.instance.client
          .from('driver_locations')
          .select('lat, lng, eta_minutes, estado')
          .eq('driver_id', driverId)
          .single();

      final lat = (row['lat'] as num?)?.toDouble();
      final lng = (row['lng'] as num?)?.toDouble();
      final etaRaw = row['eta_minutes'] as int?;
      final estado = row['estado']?.toString() ?? '';

      if (lat == null || lng == null) {
        state = state.copyWith(
          locationError: 'La ubicación del conductor aún no está disponible.',
        );
        return;
      }

      final newStatus = _resolveStatus(estado);
      final eta = etaRaw ?? state.etaMinutes;
      final banner = eta <= 2 && eta > 0;

      state = state.copyWith(
        driverPosition: GeoPoint(lat, lng),
        etaMinutes: eta,
        showArrivalBanner: banner,
        status: newStatus,
        clearLocationError: true,
      );
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          locationError:
          'No se pudo obtener la ubicación: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  ViajeStatus _resolveStatus(String estado) {
    switch (estado) {
      case 'en_viaje':
        return ViajeStatus.enRuta;
      case 'disponible':
      case 'en_ruta':
        return ViajeStatus.conductorEnCamino;
      default:
        return state.status; // no cambiar si no se reconoce
    }
  }

  void dismissAlternativePickup() {
    if (!state.showAlternativePickup) return;
    state = state.copyWith(showAlternativePickup: false);
  }

  /// Agrega un mensaje local (el mensaje real se inserta en trip_messages
  /// desde ChatScreen directamente en Supabase).
  void addLocalMessage(ViajeMessage msg) {
    if (state.readOnlyChat) return;
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void markFinished() => _finishTrip();

  void reset() {
    _cancelTimers();
    _started = false;
    _currentDriverId = null;
    state = ViajeState.initial();
  }

  void _finishTrip() {
    if (state.finished) return;
    state = state.copyWith(finished: true, readOnlyChat: true);
    _cancelTimers();
  }

  void _cancelTimers() {
    _etaTimer?.cancel();
    _locationTimer?.cancel();
    _etaTimer = null;
    _locationTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

final viajeProvider = StateNotifierProvider<ViajeController, ViajeState>(
      (ref) => ViajeController(),
);