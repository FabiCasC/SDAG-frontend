import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.vehicleIndex,
    required this.vehiclePath,
    required this.messages,
    required this.readOnlyChat,
    required this.showAlternativePickup,
    required this.alternativePickupText,
    required this.finished,
  });

  final ViajeStatus status;
  final int etaMinutes;
  final bool showArrivalBanner;
  final int vehicleIndex;
  final List<GeoPoint> vehiclePath;
  final List<ViajeMessage> messages;
  final bool readOnlyChat;
  final bool showAlternativePickup;
  final String? alternativePickupText;
  final bool finished;

  GeoPoint get vehiclePosition {
    if (vehiclePath.isEmpty) return const GeoPoint(0, 0);
    final idx = vehicleIndex.clamp(0, vehiclePath.length - 1);
    return vehiclePath[idx];
  }

  ViajeState copyWith({
    ViajeStatus? status,
    int? etaMinutes,
    bool? showArrivalBanner,
    int? vehicleIndex,
    List<GeoPoint>? vehiclePath,
    List<ViajeMessage>? messages,
    bool? readOnlyChat,
    bool? showAlternativePickup,
    String? alternativePickupText,
    bool? finished,
  }) {
    return ViajeState(
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      showArrivalBanner: showArrivalBanner ?? this.showArrivalBanner,
      vehicleIndex: vehicleIndex ?? this.vehicleIndex,
      vehiclePath: vehiclePath ?? this.vehiclePath,
      messages: messages ?? this.messages,
      readOnlyChat: readOnlyChat ?? this.readOnlyChat,
      showAlternativePickup: showAlternativePickup ?? this.showAlternativePickup,
      alternativePickupText: alternativePickupText ?? this.alternativePickupText,
      finished: finished ?? this.finished,
    );
  }

  static ViajeState initial() {
    final now = DateTime.now();
    return ViajeState(
      status: ViajeStatus.esperandoConductor,
      etaMinutes: 12,
      showArrivalBanner: false,
      vehicleIndex: 0,
      vehiclePath: const [
        GeoPoint(-12.0931, -76.9662),
        GeoPoint(-12.0860, -76.9550),
        GeoPoint(-12.0790, -76.9460),
        GeoPoint(-12.0700, -76.9360),
        GeoPoint(-12.0600, -76.9250),
        GeoPoint(-12.0464, -76.9156),
        GeoPoint(-12.0200, -76.8600),
        GeoPoint(-11.9800, -76.8000),
        GeoPoint(-11.9333, -76.7000),
      ],
      messages: [
        ViajeMessage(
          id: 'm1',
          isDriver: true,
          text: 'Hola, ya estoy en camino.',
          timestamp: now.subtract(const Duration(minutes: 6)),
        ),
        ViajeMessage(
          id: 'm2',
          isDriver: false,
          text: 'Perfecto, estaré en el punto de recojo.',
          timestamp: now.subtract(const Duration(minutes: 5)),
        ),
        ViajeMessage(
          id: 'm3',
          isDriver: true,
          text: 'Voy por la ruta indicada. Te aviso al llegar.',
          timestamp: now.subtract(const Duration(minutes: 4)),
        ),
        ViajeMessage(
          id: 'm4',
          isDriver: false,
          text: 'Gracias.',
          timestamp: now.subtract(const Duration(minutes: 3)),
        ),
      ],
      readOnlyChat: false,
      showAlternativePickup: false,
      alternativePickupText: null,
      finished: false,
    );
  }
}

class ViajeController extends StateNotifier<ViajeState> {
  ViajeController() : super(ViajeState.initial());

  Timer? _statusTimer;
  Timer? _etaTimer;
  Timer? _vehicleTimer;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _statusTimer = Timer(const Duration(seconds: 6), () {
      state = state.copyWith(status: ViajeStatus.conductorEnCamino);
      state = state.copyWith(
        showAlternativePickup: true,
        alternativePickupText: 'Entrada principal, al lado del grifo.',
      );
      _statusTimer = Timer(const Duration(seconds: 8), () {
        state = state.copyWith(status: ViajeStatus.enRuta);
      });
    });

    _etaTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (state.finished) return;
      final next = (state.etaMinutes - 1).clamp(0, 999);
      final banner = next <= 2;
      state = state.copyWith(etaMinutes: next, showArrivalBanner: banner);
      if (next == 0) {
        _finishTrip();
      }
    });

    _vehicleTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (state.finished) return;
      final next = (state.vehicleIndex + 1) % state.vehiclePath.length;
      state = state.copyWith(vehicleIndex: next);
    });
  }

  void dismissAlternativePickup() {
    if (!state.showAlternativePickup) return;
    state = state.copyWith(showAlternativePickup: false);
  }

  void sendMessage(String text) {
    if (state.readOnlyChat) return;
    final value = text.trim();
    if (value.isEmpty) return;
    final next = [
      ...state.messages,
      ViajeMessage(
        id: 'm_${DateTime.now().microsecondsSinceEpoch}',
        isDriver: false,
        text: value,
        timestamp: DateTime.now(),
      ),
    ];
    state = state.copyWith(messages: next);
  }

  void markFinished() {
    _finishTrip();
  }

  void reset() {
    _cancelTimers();
    _started = false;
    state = ViajeState.initial();
  }

  void _finishTrip() {
    if (state.finished) return;
    state = state.copyWith(finished: true, readOnlyChat: true);
    _cancelTimers();
  }

  void _cancelTimers() {
    _statusTimer?.cancel();
    _etaTimer?.cancel();
    _vehicleTimer?.cancel();
    _statusTimer = null;
    _etaTimer = null;
    _vehicleTimer = null;
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
