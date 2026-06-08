import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_data.dart';

enum ConductorEstadoViaje {
  esperando,
  lleno,
  enRuta,
  completado,
}

enum ConductorRuta {
  priale,
  javierPrado,
}

enum EstadoPasajero {
  pendiente,
  abordo,
  noAbordo,
}

enum ConductorToastType {
  success,
  error,
  warning,
  info,
}

class PasajeroViaje {
  const PasajeroViaje({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.asiento,
    required this.puntoRecojo,
    required this.estado,
    required this.fueraDeRuta,
  });

  final String id;
  final String nombre;
  final String dni;
  final int asiento;
  final String puntoRecojo;
  final EstadoPasajero estado;
  final bool fueraDeRuta;

  PasajeroViaje copyWith({
    String? id,
    String? nombre,
    String? dni,
    int? asiento,
    String? puntoRecojo,
    EstadoPasajero? estado,
    bool? fueraDeRuta,
  }) {
    return PasajeroViaje(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      dni: dni ?? this.dni,
      asiento: asiento ?? this.asiento,
      puntoRecojo: puntoRecojo ?? this.puntoRecojo,
      estado: estado ?? this.estado,
      fueraDeRuta: fueraDeRuta ?? this.fueraDeRuta,
    );
  }
}

class ConductorViajeState {
  const ConductorViajeState({
    required this.estadoViaje,
    required this.rutaSeleccionada,
    required this.totalSeats,
    required this.asientosOcupados,
    required this.pasajerosViaje,
    required this.secondsToDepart,
    required this.elapsedSeconds,
    required this.estimacionMinutos,
    required this.bannerText,
    required this.toastMessage,
    required this.toastType,
    required this.toastId,
    required this.revertSecondsLeft,
  });

  final ConductorEstadoViaje estadoViaje;
  final ConductorRuta? rutaSeleccionada;
  final int totalSeats;
  final List<int> asientosOcupados;
  final List<PasajeroViaje> pasajerosViaje;
  final int? secondsToDepart;
  final int elapsedSeconds;
  final int? estimacionMinutos;
  final String? bannerText;
  final String? toastMessage;
  final ConductorToastType? toastType;
  final int toastId;
  final int? revertSecondsLeft;

  bool get isActive => pasajerosViaje.isNotEmpty && estadoViaje != ConductorEstadoViaje.completado;
  bool get isFull => asientosOcupados.length >= totalSeats;
  bool get isForcedDeparture => false;
  int get occupiedSeats => asientosOcupados.length;
  MockTripDirection? get direction => MockTripDirection.sanIsidroToChosica;

  static const tarifaFija = 15.0;
  double get recaudacionTotal => occupiedSeats * tarifaFija;

  ConductorViajeState copyWith({
    ConductorEstadoViaje? estadoViaje,
    ConductorRuta? rutaSeleccionada,
    bool clearRutaSeleccionada = false,
    int? totalSeats,
    List<int>? asientosOcupados,
    List<PasajeroViaje>? pasajerosViaje,
    int? secondsToDepart,
    bool clearSecondsToDepart = false,
    int? elapsedSeconds,
    int? estimacionMinutos,
    bool clearEstimacion = false,
    String? bannerText,
    bool clearBanner = false,
    String? toastMessage,
    ConductorToastType? toastType,
    bool clearToast = false,
    int? toastId,
    int? revertSecondsLeft,
    bool clearRevert = false,
  }) {
    return ConductorViajeState(
      estadoViaje: estadoViaje ?? this.estadoViaje,
      rutaSeleccionada:
          clearRutaSeleccionada ? null : (rutaSeleccionada ?? this.rutaSeleccionada),
      totalSeats: totalSeats ?? this.totalSeats,
      asientosOcupados: asientosOcupados ?? this.asientosOcupados,
      pasajerosViaje: pasajerosViaje ?? this.pasajerosViaje,
      secondsToDepart: clearSecondsToDepart ? null : (secondsToDepart ?? this.secondsToDepart),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      estimacionMinutos: clearEstimacion ? null : (estimacionMinutos ?? this.estimacionMinutos),
      bannerText: clearBanner ? null : (bannerText ?? this.bannerText),
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
      toastType: clearToast ? null : (toastType ?? this.toastType),
      toastId: toastId ?? this.toastId,
      revertSecondsLeft: clearRevert ? null : (revertSecondsLeft ?? this.revertSecondsLeft),
    );
  }

  static const initial = ConductorViajeState(
    estadoViaje: ConductorEstadoViaje.esperando,
    rutaSeleccionada: null,
    totalSeats: 8,
    asientosOcupados: <int>[],
    pasajerosViaje: <PasajeroViaje>[],
    secondsToDepart: null,
    elapsedSeconds: 0,
    estimacionMinutos: null,
    bannerText: null,
    toastMessage: null,
    toastType: null,
    toastId: 0,
    revertSecondsLeft: null,
  );
}

class ConductorViajeController extends StateNotifier<ConductorViajeState> {
  ConductorViajeController() : super(ConductorViajeState.initial) {
    _bootstrap();
  }

  Timer? _countdownTimer;
  Timer? _elapsedTimer;
  Timer? _revertTimer;

  Future<void> _bootstrap() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id, capacity')
          .eq('profile_id', user.id)
          .maybeSingle();
      final driverId = driver?['id']?.toString();
      final capacity = (driver?['capacity'] as int?) ?? state.totalSeats;
      state = state.copyWith(totalSeats: capacity);
      if (driverId == null) return;

      final trip = await Supabase.instance.client
          .from('trips')
          .select('id, status')
          .eq('driver_id', driverId)
          .neq('status', 'completado')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final tripId = trip?['id']?.toString();
      if (tripId == null) return;

      final reservations = await Supabase.instance.client
          .from('reservations')
          .select('id, passenger_profile_id, pickup_point, seats, status')
          .eq('trip_id', tripId)
          .eq('status', 'activa');

      final pasajeros = <PasajeroViaje>[];
      final occupied = <int>{};
      for (final rm in (reservations as List).cast<Map<String, dynamic>>()) {
        final passengerId = rm['passenger_profile_id']?.toString();
        final pickup = rm['pickup_point']?.toString() ?? '—';
        final seats = rm['seats'];
          if (passengerId == null || seats is! List) continue;

          final profile = await Supabase.instance.client
              .from('profiles')
              .select('name, dni')
              .eq('id', passengerId)
              .maybeSingle();
          final name = profile?['name']?.toString() ?? 'Pasajero';
          final dni = profile?['dni']?.toString() ?? '—';

          for (final s in seats) {
            if (s is! int) continue;
            occupied.add(s);
            pasajeros.add(
              PasajeroViaje(
                id: passengerId,
                nombre: name,
                dni: dni,
                asiento: s,
                puntoRecojo: pickup,
                estado: EstadoPasajero.pendiente,
                fueraDeRuta: false,
              ),
            );
          }
      }

      pasajeros.sort((a, b) => a.asiento.compareTo(b.asiento));
      final seatsSorted = occupied.toList()..sort();
      final estado = seatsSorted.length >= state.totalSeats ? ConductorEstadoViaje.lleno : ConductorEstadoViaje.esperando;
      state = state.copyWith(
        pasajerosViaje: pasajeros,
        asientosOcupados: seatsSorted,
        estadoViaje: estado,
        estimacionMinutos: _estimateMinutes(seatsSorted.length),
      );
    } catch (_) {}
  }

  int? _estimateMinutes(int occupied) {
    if (occupied <= 0) return null;
    final remaining = (state.totalSeats - occupied).clamp(0, state.totalSeats);
    if (remaining == 0) return 0;
    return remaining * 4;
  }

  void _toast(ConductorToastType type, String message) {
    state = state.copyWith(
      toastMessage: message,
      toastType: type,
      toastId: state.toastId + 1,
    );
  }

  void clearToast() {
    state = state.copyWith(clearToast: true);
  }

  void clearBanner() {
    state = state.copyWith(clearBanner: true);
  }

  void seleccionarRuta(ConductorRuta ruta) {
    state = state.copyWith(rutaSeleccionada: ruta);
  }

  void simularUltimoAsiento() {
    if (state.isFull) return;
    final used = state.asientosOcupados.toSet();
    int seat = 1;
    while (seat <= state.totalSeats && used.contains(seat)) {
      seat += 1;
    }
    if (seat > state.totalSeats) return;
    final id = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    final next = PasajeroViaje(
      id: id,
      nombre: 'Pasajero',
      dni: '00000000',
      asiento: seat,
      puntoRecojo: 'Punto por confirmar',
      estado: EstadoPasajero.pendiente,
      fueraDeRuta: false,
    );
    final pasajeros = [...state.pasajerosViaje, next]..sort((a, b) => a.asiento.compareTo(b.asiento));
    final seats = {...state.asientosOcupados, seat}.toList()..sort();
    final nextEstado = seats.length >= state.totalSeats ? ConductorEstadoViaje.lleno : ConductorEstadoViaje.esperando;
    state = state.copyWith(
      pasajerosViaje: pasajeros,
      asientosOcupados: seats,
      estadoViaje: nextEstado,
      estimacionMinutos: _estimateMinutes(seats.length),
    );
    if (nextEstado == ConductorEstadoViaje.lleno) {
      _toast(ConductorToastType.success, '¡Vehículo completo!');
      _startCountdown();
    }
  }

  void cancelarReserva(String pasajeroId) {
    final p = state.pasajerosViaje.where((e) => e.id == pasajeroId).toList();
    if (p.isEmpty) return;
    final seat = p.first.asiento;
    final pasajeros = state.pasajerosViaje.where((e) => e.id != pasajeroId).toList();
    final seats = state.asientosOcupados.where((s) => s != seat).toList()..sort();
    final wasFull = state.estadoViaje == ConductorEstadoViaje.lleno;
    final nowFull = seats.length >= state.totalSeats;
    var nextEstado = state.estadoViaje;
    if (wasFull && !nowFull) {
      nextEstado = ConductorEstadoViaje.esperando;
      _stopCountdown();
      _toast(ConductorToastType.warning, 'Se liberó un asiento. Se detuvo la salida.');
    }
    state = state.copyWith(
      pasajerosViaje: pasajeros,
      asientosOcupados: seats,
      estadoViaje: nextEstado,
      bannerText: '${p.first.nombre} canceló su reserva. Asiento $seat disponible.',
      estimacionMinutos: _estimateMinutes(seats.length),
    );
  }

  void actualizarEstadoPasajero({
    required String pasajeroId,
    required EstadoPasajero estado,
  }) {
    final pasajeros = state.pasajerosViaje
        .map((p) => p.id == pasajeroId ? p.copyWith(estado: estado) : p)
        .toList();
    state = state.copyWith(pasajerosViaje: pasajeros);
  }

  void iniciarRuta({bool auto = false}) {
    if (!state.isFull && !auto) {
      _toast(ConductorToastType.warning, 'El vehículo debe estar completo para partir');
      return;
    }
    _stopCountdown();
    _stopRevert();
    state = state.copyWith(
      estadoViaje: ConductorEstadoViaje.enRuta,
      elapsedSeconds: 0,
      clearSecondsToDepart: true,
      clearRevert: true,
    );
    _startElapsed();
    if (auto) {
      _toast(ConductorToastType.info, 'Salida registrada automáticamente');
    }
  }

  void completarRuta() {
    _stopCountdown();
    _stopElapsed();
    state = state.copyWith(
      estadoViaje: ConductorEstadoViaje.completado,
      revertSecondsLeft: 120,
    );
    _startRevertTimer();
  }

  void revertirCompletarRuta() {
    if (state.revertSecondsLeft == null || state.revertSecondsLeft! <= 0) return;
    _stopRevert();
    state = state.copyWith(
      estadoViaje: ConductorEstadoViaje.enRuta,
      clearRevert: true,
    );
    _startElapsed();
  }

  void _startCountdown() {
    _stopCountdown();
    state = state.copyWith(secondsToDepart: 180);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.secondsToDepart;
      if (current == null) return;
      final next = current - 1;
      if (next == 30) {
        _toast(ConductorToastType.error, '¡30 segundos para partir!');
      }
      if (next <= 0) {
        _stopCountdown();
        iniciarRuta(auto: true);
        return;
      }
      state = state.copyWith(secondsToDepart: next);
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = state.copyWith(clearSecondsToDepart: true);
  }

  void _startElapsed() {
    _stopElapsed();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _stopElapsed() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  void _startRevertTimer() {
    _stopRevert();
    _revertTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.revertSecondsLeft;
      if (current == null) return;
      final next = current - 1;
      if (next <= 0) {
        _stopRevert();
        state = state.copyWith(clearRevert: true);
        return;
      }
      state = state.copyWith(revertSecondsLeft: next);
    });
  }

  void _stopRevert() {
    _revertTimer?.cancel();
    _revertTimer = null;
  }

  @override
  void dispose() {
    _stopCountdown();
    _stopElapsed();
    _stopRevert();
    super.dispose();
  }
}

final conductorViajeProvider =
    StateNotifierProvider<ConductorViajeController, ConductorViajeState>(
  (ref) => ConductorViajeController(),
);
