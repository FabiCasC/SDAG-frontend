import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConductorOnlineItem {
  const ConductorOnlineItem({
    required this.name,
    required this.plate,
    required this.status,
  });

  final String name;
  final String plate;
  final String status;
}

class ConductorGroupMessage {
  const ConductorGroupMessage({
    required this.id,
    required this.senderName,
    required this.senderPlate,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String senderName;
  final String senderPlate;
  final String text;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'senderPlate': senderPlate,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  static ConductorGroupMessage? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final senderName = json['senderName'] as String?;
    final senderPlate = json['senderPlate'] as String?;
    final text = json['text'] as String?;
    final ts = json['timestamp'] as String?;
    if (id == null || senderName == null || senderPlate == null || text == null || ts == null) {
      return null;
    }
    final timestamp = DateTime.tryParse(ts);
    if (timestamp == null) return null;
    return ConductorGroupMessage(
      id: id,
      senderName: senderName,
      senderPlate: senderPlate,
      text: text,
      timestamp: timestamp,
    );
  }
}

class ConductorChatGrupalState {
  const ConductorChatGrupalState({
    required this.online,
    required this.messages,
  });

  final List<ConductorOnlineItem> online;
  final List<ConductorGroupMessage> messages;

  static ConductorChatGrupalState initial() {
    final now = DateTime.now();
    return ConductorChatGrupalState(
      online: const [
        ConductorOnlineItem(name: 'Jorge Mamani', plate: 'ABC-456', status: 'En ruta'),
        ConductorOnlineItem(name: 'Luis Quispe', plate: 'DEF-789', status: 'Disponible'),
        ConductorOnlineItem(name: 'Pedro Huanca', plate: 'GHI-321', status: 'En ruta'),
      ],
      messages: [
        ConductorGroupMessage(
          id: 'g1',
          senderName: 'Jorge Mamani',
          senderPlate: 'ABC-456',
          text: 'Tráfico pesado por Javier Prado. Tomen precaución.',
          timestamp: now.subtract(const Duration(minutes: 8)),
        ),
        ConductorGroupMessage(
          id: 'g2',
          senderName: 'Luis Quispe',
          senderPlate: 'DEF-789',
          text: 'Confirmo, también está lento. Yo iré por La Priale.',
          timestamp: now.subtract(const Duration(minutes: 7)),
        ),
        ConductorGroupMessage(
          id: 'g3',
          senderName: 'Pedro Huanca',
          senderPlate: 'GHI-321',
          text: 'En ruta a San Isidro. ¿Alguien vio operativo en Chosica centro?',
          timestamp: now.subtract(const Duration(minutes: 6)),
        ),
        ConductorGroupMessage(
          id: 'g4',
          senderName: 'Jorge Mamani',
          senderPlate: 'ABC-456',
          text: 'Sí, PNP en Av. Lima. Mejor desvío.',
          timestamp: now.subtract(const Duration(minutes: 5)),
        ),
        ConductorGroupMessage(
          id: 'g5',
          senderName: 'Luis Quispe',
          senderPlate: 'DEF-789',
          text: 'Gracias por el dato.',
          timestamp: now.subtract(const Duration(minutes: 4)),
        ),
      ],
    );
  }
}

class ConductorChatGrupalController extends StateNotifier<ConductorChatGrupalState> {
  ConductorChatGrupalController() : super(ConductorChatGrupalState.initial()) {
    _load();
  }

  static const _prefsKey = 'sdag_admin_driver_group_chat';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final decoded = _decode(raw);
    if (decoded.isEmpty) return;
    state = ConductorChatGrupalState(
      online: state.online,
      messages: decoded,
    );
  }

  Future<void> send({
    required String senderName,
    required String senderPlate,
    required String text,
  }) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final next = [
      ...state.messages,
      ConductorGroupMessage(
        id: 'g_${DateTime.now().microsecondsSinceEpoch}',
        senderName: senderName,
        senderPlate: senderPlate,
        text: value,
        timestamp: DateTime.now(),
      ),
    ];
    state = ConductorChatGrupalState(online: state.online, messages: next);
    await _persist(next);
  }

  Future<void> _persist(List<ConductorGroupMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  List<ConductorGroupMessage> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <ConductorGroupMessage>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final m = ConductorGroupMessage.fromJson(item);
          if (m != null) out.add(m);
        } else if (item is Map) {
          final m = ConductorGroupMessage.fromJson(item.cast<String, dynamic>());
          if (m != null) out.add(m);
        }
      }
      out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return out;
    } catch (_) {
      return const [];
    }
  }
}

final conductorChatGrupalProvider =
    StateNotifierProvider<ConductorChatGrupalController, ConductorChatGrupalState>(
  (ref) => ConductorChatGrupalController(),
);
