import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConductorChatMessage {
  const ConductorChatMessage({
    required this.id,
    required this.isConductor,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final bool isConductor;
  final String text;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'isConductor': isConductor,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  static ConductorChatMessage? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final isConductor = json['isConductor'];
    final text = json['text'] as String?;
    final ts = json['timestamp'] as String?;
    if (id == null || isConductor is! bool || text == null || ts == null) return null;
    final timestamp = DateTime.tryParse(ts);
    if (timestamp == null) return null;
    return ConductorChatMessage(
      id: id,
      isConductor: isConductor,
      text: text,
      timestamp: timestamp,
    );
  }
}

class ConductorChatController extends StateNotifier<Map<String, List<ConductorChatMessage>>> {
  ConductorChatController() : super(const {}) {
    _loadAll();
  }

  static const _keyPrefix = 'sdag_conductor_chat_';

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
    final next = <String, List<ConductorChatMessage>>{};
    for (final k in keys) {
      final passengerId = k.substring(_keyPrefix.length);
      final raw = prefs.getString(k);
      if (raw == null) continue;
      final decoded = _decode(raw);
      if (decoded.isNotEmpty) next[passengerId] = decoded;
    }
    state = next;
  }

  List<ConductorChatMessage> messagesFor(String passengerId) {
    final existing = state[passengerId];
    if (existing != null && existing.isNotEmpty) return existing;
    final seeded = _seedMessages(passengerId);
    state = {...state, passengerId: seeded};
    _persist(passengerId, seeded);
    return seeded;
  }

  Future<void> sendMessage({
    required String passengerId,
    required bool fromConductor,
    required String text,
  }) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final current = [...(state[passengerId] ?? messagesFor(passengerId))];
    final next = [
      ...current,
      ConductorChatMessage(
        id: 'm_${DateTime.now().microsecondsSinceEpoch}',
        isConductor: fromConductor,
        text: value,
        timestamp: DateTime.now(),
      ),
    ];
    state = {...state, passengerId: next};
    await _persist(passengerId, next);
  }

  Future<void> sendAlternativePickup({
    required String passengerId,
    required String text,
  }) async {
    final v = text.trim();
    if (v.isEmpty) return;
    await sendMessage(
      passengerId: passengerId,
      fromConductor: true,
      text: '📍 Punto de recojo alternativo: $v',
    );
  }

  Future<void> _persist(String passengerId, List<ConductorChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$passengerId';
    final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(key, raw);
  }

  List<ConductorChatMessage> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <ConductorChatMessage>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final m = ConductorChatMessage.fromJson(item);
          if (m != null) out.add(m);
        } else if (item is Map) {
          final m = ConductorChatMessage.fromJson(item.cast<String, dynamic>());
          if (m != null) out.add(m);
        }
      }
      out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return out;
    } catch (_) {
      return const [];
    }
  }

  List<ConductorChatMessage> _seedMessages(String passengerId) {
    final now = DateTime.now();
    return [
      ConductorChatMessage(
        id: 'seed1_$passengerId',
        isConductor: false,
        text: 'Hola, ya estoy en el punto.',
        timestamp: now.subtract(const Duration(minutes: 6)),
      ),
      ConductorChatMessage(
        id: 'seed2_$passengerId',
        isConductor: true,
        text: 'Perfecto, en 3 min llego.',
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
      ConductorChatMessage(
        id: 'seed3_$passengerId',
        isConductor: false,
        text: 'Listo, estoy atento.',
        timestamp: now.subtract(const Duration(minutes: 4)),
      ),
      ConductorChatMessage(
        id: 'seed4_$passengerId',
        isConductor: true,
        text: 'Gracias, te aviso al llegar.',
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    ];
  }
}

final conductorChatProvider =
    StateNotifierProvider<ConductorChatController, Map<String, List<ConductorChatMessage>>>(
  (ref) => ConductorChatController(),
);

