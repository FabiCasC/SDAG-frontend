import 'package:flutter_tts/flutter_tts.dart';

/// Síntesis de voz para alertas del conductor (RF-034).
class ConductorTtsService {
  ConductorTtsService._();

  static final ConductorTtsService instance = ConductorTtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  String? _lastSpoken;

  Future<void> initialize() async {
    if (_ready) return;
    await _tts.setLanguage('es-PE');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _ready = true;
  }

  Future<void> speak(String text, {required bool enabled}) async {
    if (!enabled) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == _lastSpoken) return;

    await initialize();
    _lastSpoken = trimmed;
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  Future<void> speakNextStop({
    required bool enabled,
    required String passengerName,
    required String pickupPoint,
  }) async {
    final point = pickupPoint.trim().isEmpty ? passengerName : pickupPoint;
    await speak('Próxima parada: $point', enabled: enabled);
  }

  void resetLastSpoken() {
    _lastSpoken = null;
  }
}
