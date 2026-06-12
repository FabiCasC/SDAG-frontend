import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'conductor_viaje_provider.dart';

class ConductorVoiceState {
  const ConductorVoiceState({
    required this.enabled,
    required this.bannerText,
    required this.bannerId,
  });

  final bool enabled;
  final String? bannerText;
  final int bannerId;

  ConductorVoiceState copyWith({
    bool? enabled,
    String? bannerText,
    bool clearBanner = false,
    int? bannerId,
  }) {
    return ConductorVoiceState(
      enabled: enabled ?? this.enabled,
      bannerText: clearBanner ? null : (bannerText ?? this.bannerText),
      bannerId: bannerId ?? this.bannerId,
    );
  }

  static const initial = ConductorVoiceState(enabled: true, bannerText: null, bannerId: 0);
}

class ConductorVoiceController extends StateNotifier<ConductorVoiceState> {
  ConductorVoiceController() : super(ConductorVoiceState.initial) {
    _load();
  }

  static const _prefsKey = 'sdag_conductor_voice_enabled';

  Timer? _nearPickupTimer;
  String? _lastNextPassengerId;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_prefsKey);
    if (v == null) return;
    state = state.copyWith(enabled: v);
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }

  void clearBanner() {
    state = state.copyWith(clearBanner: true);
  }

  void _emit(String text) {
    if (!state.enabled) return;
    state = state.copyWith(bannerText: '🔊 $text', bannerId: state.bannerId + 1);
  }

  void onViajeChanged(ConductorViajeState? prev, ConductorViajeState next) {
    if (!state.enabled) return;

    final nowEnRuta = next.estadoViaje == ConductorEstadoViaje.enRuta;
    final wasEnRuta = prev?.estadoViaje == ConductorEstadoViaje.enRuta;
    if (nowEnRuta && !wasEnRuta) {
      final nextPassenger = _nextPending(next);
      if (nextPassenger != null) {
        _lastNextPassengerId = nextPassenger.id;
        _emit('Próxima parada: ${nextPassenger.nombre}');
      }
      _nearPickupTimer?.cancel();
      _nearPickupTimer = Timer(const Duration(seconds: 12), () {
        final pending = _nextPending(next);
        if (pending != null) {
          _emit('Pasajero cerca del punto de recojo');
        }
      });
    }

    if (nowEnRuta) {
      final nextPassenger = _nextPending(next);
      if (nextPassenger != null && nextPassenger.id != _lastNextPassengerId) {
        _lastNextPassengerId = nextPassenger.id;
        _emit('Próxima parada: ${nextPassenger.nombre}');
      }
    }
  }

  PasajeroViaje? _nextPending(ConductorViajeState state) {
    final pending = state.pasajerosViaje
        .where((p) => p.estado == EstadoPasajero.pendiente)
        .toList()
      ..sort((a, b) => a.asiento.compareTo(b.asiento));
    return pending.isEmpty ? null : pending.first;
  }

  @override
  void dispose() {
    _nearPickupTimer?.cancel();
    super.dispose();
  }
}

final conductorVoiceProvider =
    StateNotifierProvider<ConductorVoiceController, ConductorVoiceState>((ref) {
  final controller = ConductorVoiceController();
  ref.listen<ConductorViajeState>(conductorViajeProvider, (prev, next) {
    controller.onViajeChanged(prev, next);
  });
  return controller;
});

