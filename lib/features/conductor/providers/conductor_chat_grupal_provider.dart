import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.senderPlate,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String senderPlate;
  final String text;
  final DateTime timestamp;
}

class ConductorChatGrupalState {
  const ConductorChatGrupalState({
    required this.online,
    required this.messages,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserRole,
    required this.currentUserPlate,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<ConductorOnlineItem> online;
  final List<ConductorGroupMessage> messages;
  final String? currentUserId;
  final String currentUserName;
  final String currentUserRole;
  final String currentUserPlate;
  final bool isLoading;
  final String? errorMessage;

  ConductorChatGrupalState copyWith({
    List<ConductorOnlineItem>? online,
    List<ConductorGroupMessage>? messages,
    String? currentUserId,
    String? currentUserName,
    String? currentUserRole,
    String? currentUserPlate,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConductorChatGrupalState(
      online: online ?? this.online,
      messages: messages ?? this.messages,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserName: currentUserName ?? this.currentUserName,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      currentUserPlate: currentUserPlate ?? this.currentUserPlate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const initial = ConductorChatGrupalState(
    online: [],
    messages: [],
    currentUserId: null,
    currentUserName: '',
    currentUserRole: '',
    currentUserPlate: '',
    isLoading: true,
    errorMessage: null,
  );
}

class ConductorChatGrupalController extends StateNotifier<ConductorChatGrupalState> {
  ConductorChatGrupalController() : super(ConductorChatGrupalState.initial) {
    _initialize();
  }

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _alive = true;

  Future<void> _initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No hay una sesión activa.',
      );
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id, name, role, first_name, last_name')
          .eq('id', user.id)
          .maybeSingle();

      final driver = await Supabase.instance.client
          .from('drivers')
          .select('plate')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (!_alive) return;

      state = state.copyWith(
        currentUserId: user.id,
        currentUserName: _profileName(profile),
        currentUserRole: profile?['role']?.toString() ?? 'driver',
        currentUserPlate: driver?['plate']?.toString() ?? '',
        isLoading: true,
        clearError: true,
      );

      await _loadMessages();
      _subscribe();
    } catch (error) {
      if (!_alive) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> _loadMessages() async {
    final messages = await Supabase.instance.client.from('driver_group_messages').select(
          'id, body, message, sender_id, sender_driver_id, sender_name, sender_role, sender_plate, created_at',
        ).order('created_at', ascending: true).limit(50);

    if (!_alive) return;

    final parsed = (messages as List)
        .cast<Map<String, dynamic>>()
        .map(_messageFromRow)
        .whereType<ConductorGroupMessage>()
        .toList(growable: false);

    state = state.copyWith(
      messages: parsed,
      isLoading: false,
      clearError: true,
    );
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('driver_group_messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) {
          if (!_alive) return;
          try {
            final mapped = data
                .map(_messageFromRow)
                .whereType<ConductorGroupMessage>()
                .toList()
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
            final trimmed = mapped.length <= 50 ? mapped : mapped.sublist(mapped.length - 50);
            state = state.copyWith(
              messages: trimmed,
              isLoading: false,
              clearError: true,
            );
          } catch (error) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: error.toString(),
            );
          }
        });
  }

  Future<void> send({required String text}) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión activa.');
    }

    final profile = await Supabase.instance.client.from('profiles').select('name, role').eq('id', user.id).single();

    var plate = '';
    String? driverId;
    if (profile['role']?.toString() == 'driver') {
      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id, plate')
          .eq('profile_id', user.id)
          .maybeSingle();
      driverId = driver?['id']?.toString();
      plate = driver?['plate']?.toString() ?? '';
    }

    final name = profile['name']?.toString().trim().isNotEmpty == true
        ? profile['name'].toString()
        : state.currentUserName.isNotEmpty
            ? state.currentUserName
            : 'Usuario';

    await Supabase.instance.client.from('driver_group_messages').insert({
      'sender_id': user.id,
      'sender_driver_id': driverId,
      'body': value,
      'message': value,
      'sender_name': name,
      'sender_role': profile['role']?.toString() ?? 'driver',
      'sender_plate': plate,
    });
  }

  static ConductorGroupMessage? _messageFromRow(Map<String, dynamic> row) {
    final text = row['body']?.toString() ?? row['message']?.toString();
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
    if (text == null || text.trim().isEmpty || createdAt == null) return null;

    return ConductorGroupMessage(
      id: row['id']?.toString() ?? '',
      senderId: row['sender_id']?.toString() ?? row['sender_driver_id']?.toString() ?? '',
      senderName: row['sender_name']?.toString().trim().isNotEmpty == true
          ? row['sender_name'].toString()
          : 'Usuario',
      senderRole: row['sender_role']?.toString() ?? 'driver',
      senderPlate: row['sender_plate']?.toString() ?? '',
      text: text.trim(),
      timestamp: createdAt,
    );
  }

  @override
  void dispose() {
    _alive = false;
    _subscription?.cancel();
    super.dispose();
  }
}

String _profileName(
  Map<String, dynamic>? profile, {
  String? fallback,
}) {
  final rawName = profile?['name']?.toString().trim() ?? '';
  if (rawName.isNotEmpty) return rawName;

  final firstName = profile?['first_name']?.toString().trim() ?? '';
  final lastName = profile?['last_name']?.toString().trim() ?? '';
  final fullName = '$firstName $lastName'.trim();
  if (fullName.isNotEmpty) return fullName;

  final fallbackName = fallback?.trim() ?? '';
  return fallbackName.isEmpty ? 'Usuario' : fallbackName;
}

/// Acceso al chat grupal: admin y conductores autenticados (sin restricción de horario).
final conductorChatGrupalAccesoProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;

  try {
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final role = profile['role']?.toString();
    return role == 'admin' || role == 'driver';
  } catch (_) {
    return false;
  }
});

final conductorChatGrupalProvider =
    StateNotifierProvider<ConductorChatGrupalController, ConductorChatGrupalState>(
  (ref) => ConductorChatGrupalController(),
);
