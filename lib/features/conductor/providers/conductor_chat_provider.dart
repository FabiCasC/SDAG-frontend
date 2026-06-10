import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConductorTripChatMessage {
  const ConductorTripChatMessage({
    required this.id,
    required this.senderProfileId,
    required this.text,
    required this.timestamp,
    required this.isFromDriver,
  });

  final String id;
  final String senderProfileId;
  final String text;
  final DateTime timestamp;
  final bool isFromDriver;
}

class ConductorTripChatState {
  const ConductorTripChatState({
    required this.messages,
    required this.loading,
    required this.errorMessage,
  });

  final List<ConductorTripChatMessage> messages;
  final bool loading;
  final String? errorMessage;

  ConductorTripChatState copyWith({
    List<ConductorTripChatMessage>? messages,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConductorTripChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const initial = ConductorTripChatState(
    messages: [],
    loading: true,
    errorMessage: null,
  );
}

/// Chat temporal trip ↔ pasajero. Clave: `tripId|passengerProfileId`.
final conductorTripChatProvider =
    StateNotifierProvider.autoDispose.family<ConductorTripChatController, ConductorTripChatState, String>(
  (ref, key) {
    final sep = key.indexOf('|');
    if (sep <= 0 || sep >= key.length - 1) {
      return ConductorTripChatController.invalid();
    }
    final tripId = key.substring(0, sep);
    final passengerId = key.substring(sep + 1);
    return ConductorTripChatController(
      tripId: tripId,
      passengerProfileId: passengerId,
    );
  },
);

class ConductorTripChatController extends StateNotifier<ConductorTripChatState> {
  ConductorTripChatController({
    required this.tripId,
    required this.passengerProfileId,
  }) : super(ConductorTripChatState.initial) {
    _init();
  }

  ConductorTripChatController.invalid()
      : tripId = '',
        passengerProfileId = '',
        super(
          const ConductorTripChatState(
            messages: [],
            loading: false,
            errorMessage: 'Parámetros inválidos.',
          ),
        );

  final String tripId;
  final String passengerProfileId;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _alive = true;
  String? _currentUserId;

  bool get _invalid => tripId.isEmpty || passengerProfileId.isEmpty;

  Future<void> _init() async {
    if (_invalid) return;

    final user = Supabase.instance.client.auth.currentUser;
    _currentUserId = user?.id;
    if (user == null) {
      state = state.copyWith(loading: false, errorMessage: 'No hay una sesión activa.');
      return;
    }

    try {
      await _loadInitial();
      _subscribe();
    } catch (e) {
      if (!_alive) return;
      state = state.copyWith(loading: false, errorMessage: e.toString());
    }
  }

  Future<void> _loadInitial() async {
    final pid = passengerProfileId;
    dynamic rows;
    try {
      rows = await Supabase.instance.client
          .from('trip_messages')
          .select(
            'id, message, body, sender_id, passenger_id, created_at, profiles:sender_id(name)',
          )
          .eq('trip_id', tripId)
          .or('passenger_id.eq.$pid,sender_id.eq.$pid')
          .order('created_at', ascending: true);
    } catch (_) {
      rows = await Supabase.instance.client
          .from('trip_messages')
          .select('id, message, body, sender_id, passenger_id, created_at')
          .eq('trip_id', tripId)
          .or('passenger_id.eq.$pid,sender_id.eq.$pid')
          .order('created_at', ascending: true);
    }

    if (!_alive) return;

    final list = (rows as List).cast<Map<String, dynamic>>();
    final messages = _mapRows(list);
    state = state.copyWith(messages: messages, loading: false, clearError: true);
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at')
        .listen((data) {
          if (!_alive) return;
          try {
            final filtered = data.where((m) {
              final msgPassenger = m['passenger_id']?.toString();
              final sender = m['sender_id']?.toString();
              return msgPassenger == passengerProfileId || sender == passengerProfileId;
            }).toList();

            final messages = _mapRows(filtered.cast<Map<String, dynamic>>());
            state = state.copyWith(messages: messages, loading: false, clearError: true);
          } catch (e) {
            state = state.copyWith(loading: false, errorMessage: e.toString());
          }
        });
  }

  List<ConductorTripChatMessage> _mapRows(List<Map<String, dynamic>> rows) {
    final uid = _currentUserId ?? Supabase.instance.client.auth.currentUser?.id ?? '';

    final out = <ConductorTripChatMessage>[];
    for (final r in rows) {
      final id = r['id']?.toString() ?? '';
      final sender = r['sender_id']?.toString() ?? r['sender_profile_id']?.toString() ?? '';
      final text = r['message']?.toString() ?? r['body']?.toString();
      final ts = DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal();
      if (text == null || text.trim().isEmpty || ts == null) continue;

      final isDriver = sender == uid;
      out.add(
        ConductorTripChatMessage(
          id: id,
          senderProfileId: sender,
          text: text.trim(),
          timestamp: ts,
          isFromDriver: isDriver,
        ),
      );
    }
    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }

  Future<void> sendMessage(String text) async {
    final value = text.trim();
    if (value.isEmpty || _invalid) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('trip_messages').insert({
      'trip_id': tripId,
      'passenger_id': passengerProfileId,
      'sender_id': user.id,
      'sender_profile_id': user.id,
      'message': value,
      'body': value,
      'sender_role': 'driver',
      'message_type': 'normal',
    });
  }

  Future<void> sendAlternativePickup(String text) async {
    final v = text.trim();
    if (v.isEmpty) return;
    await sendMessage('📍 Punto de recojo alternativo: $v');
  }

  @override
  void dispose() {
    _alive = false;
    _subscription?.cancel();
    super.dispose();
  }
}
