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
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
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
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> _loadMessages() async {
    final messages = await Supabase.instance.client
        .from('driver_group_messages')
        .select('*, profiles(name, role)')
        .order('created_at', ascending: true)
        .limit(50);

    final parsed = (messages as List)
        .cast<Map<String, dynamic>>()
        .map(_messageFromJoinedRow)
        .whereType<ConductorGroupMessage>()
        .toList(growable: false);

    if (!mounted) return;
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
        .listen((data) async {
          try {
            final mapped = await _mapStreamRows(data);
            if (!mounted) return;
            state = state.copyWith(
              messages: mapped,
              isLoading: false,
              clearError: true,
            );
          } catch (error) {
            if (!mounted) return;
            state = state.copyWith(
              isLoading: false,
              errorMessage: error.toString(),
            );
          }
        });
  }

  Future<List<ConductorGroupMessage>> _mapStreamRows(List<Map<String, dynamic>> data) async {
    final senderIds = data
        .map((row) => row['sender_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final profileById = <String, Map<String, dynamic>>{};
    if (senderIds.isNotEmpty) {
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('id, name, role')
          .inFilter('id', senderIds);

      for (final item in (profiles as List).cast<Map<String, dynamic>>()) {
        final id = item['id']?.toString();
        if (id != null && id.isNotEmpty) {
          profileById[id] = item;
        }
      }
    }

    final messages = data
        .map((row) => _messageFromStreamRow(row, profileById))
        .whereType<ConductorGroupMessage>()
        .toList(growable: false);

    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (messages.length <= 50) return messages;
    return messages.sublist(messages.length - 50);
  }

  Future<void> send({required String text}) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión activa.');
    }

    final userRole = state.currentUserRole.isEmpty ? 'driver' : state.currentUserRole;

    await Supabase.instance.client.from('driver_group_messages').insert({
      'sender_id': user.id,
      'message': value,
      'sender_role': userRole,
      'sender_name': state.currentUserName.isEmpty ? 'Usuario' : state.currentUserName,
      'sender_plate': state.currentUserPlate.isEmpty ? userRole.toUpperCase() : state.currentUserPlate,
      'body': value,
    });
  }

  ConductorGroupMessage? _messageFromJoinedRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final text = row['message']?.toString() ?? row['body']?.toString();
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
    if (text == null || text.trim().isEmpty || createdAt == null) return null;

    return ConductorGroupMessage(
      id: row['id']?.toString() ?? '',
      senderId: row['sender_id']?.toString() ?? '',
      senderName: _profileName(profile, fallback: row['sender_name']?.toString()),
      senderRole: row['sender_role']?.toString() ?? profile?['role']?.toString() ?? 'driver',
      text: text.trim(),
      timestamp: createdAt,
    );
  }

  ConductorGroupMessage? _messageFromStreamRow(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> profileById,
  ) {
    final senderId = row['sender_id']?.toString() ?? '';
    final profile = profileById[senderId];
    final text = row['message']?.toString() ?? row['body']?.toString();
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
    if (text == null || text.trim().isEmpty || createdAt == null) return null;

    return ConductorGroupMessage(
      id: row['id']?.toString() ?? '',
      senderId: senderId,
      senderName: _profileName(profile, fallback: row['sender_name']?.toString()),
      senderRole: row['sender_role']?.toString() ?? profile?['role']?.toString() ?? 'driver',
      text: text.trim(),
      timestamp: createdAt,
    );
  }

  @override
  void dispose() {
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

final conductorChatGrupalProvider =
    StateNotifierProvider<ConductorChatGrupalController, ConductorChatGrupalState>(
  (ref) => ConductorChatGrupalController(),
);
