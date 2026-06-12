// lib/features/viaje/screens/chat_screen.dart
//
// Chat en tiempo real con el conductor.
// Mensajes activos: leídos desde trip_messages via Supabase Realtime.
// Mensajes históricos (readonly): cargados una vez por FutureBuilder.
// Inserción: directamente en trip_messages con sender_profile_id = auth.uid()

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

// ─── Data model ─────────────────────────────────────────────────────────────

class _ChatEntry {
  const _ChatEntry({
    required this.id,
    required this.isDriver,
    required this.text,
    required this.time,
  });

  final String id;
  final bool isDriver;
  final String text;
  final String time;
}

// ─── Widget principal ────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Canal Realtime activo (solo en modo activo, no readonly)
  RealtimeChannel? _channel;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  List<_ChatEntry> _messages = const [];
  bool _sending = false;
  String? _errorMsg;

  String? _activeTripId;   // trip_id de la reserva activa
  String? _driverName;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _sub?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Modo activo: suscripción Realtime ──────────────────────────────────────

  void _initRealtime(String tripId) {
    if (_channel != null) return; // ya suscrito

    _activeTripId = tripId;

    // Carga inicial
    _loadMessages(tripId);

    // Suscripción a cambios (INSERT)
    _channel = Supabase.instance.client
        .channel('trip_messages:$tripId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'trip_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'trip_id',
        value: tripId,
      ),
      callback: (payload) {
        final row = payload.newRecord;
        _appendRow(row);
      },
    )
        .subscribe();
  }

  Future<void> _loadMessages(String tripId) async {
    try {
      final rows = await Supabase.instance.client
          .from('trip_messages')
          .select('id, sender_role, message, body, created_at')
          .eq('trip_id', tripId)
          .order('created_at', ascending: true);

      if (!mounted) return;
      final entries = (rows as List)
          .cast<Map<String, dynamic>>()
          .map(_rowToEntry)
          .toList();
      setState(() {
        _messages = entries;
        _errorMsg = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'No se pudieron cargar los mensajes.';
      });
    }
  }

  void _appendRow(Map<String, dynamic> row) {
    final entry = _rowToEntry(row);
    // Evitar duplicados por Realtime + carga inicial
    if (_messages.any((m) => m.id == entry.id)) return;
    setState(() {
      _messages = [..._messages, entry];
    });
    _scrollToBottom();
  }

  _ChatEntry _rowToEntry(Map<String, dynamic> row) {
    final text = row['message']?.toString().trim().isNotEmpty == true
        ? row['message'].toString()
        : (row['body']?.toString() ?? '');
    return _ChatEntry(
      id: row['id']?.toString() ?? UniqueKey().toString(),
      isDriver: row['sender_role']?.toString() == 'driver',
      text: text,
      time: _formatRawTime(row['created_at']?.toString()),
    );
  }

  // ── Enviar mensaje ─────────────────────────────────────────────────────────

  Future<void> _send(String tripId) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _sending = true);
    _textCtrl.clear();

    try {
      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': tripId,
        'sender_profile_id': uid,
        'sender_id': uid,
        'sender_role': 'passenger',
        'message': text,
        'body': text,
      });
      // El Realtime listener lo agregará a _messages automáticamente.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'No se pudo enviar el mensaje.';
        // Re-poner el texto para que el usuario no lo pierda
        _textCtrl.text = text;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final qs = GoRouterState.of(context).uri.queryParameters;
    final readonly = qs['readonly'] == '1';
    final reservationId = qs['tripId']; // en modo readonly este param = reservationId

    if (readonly) {
      return FutureBuilder<_ReadonlyChatData?>(
        future: _loadReadonlyChatData(reservationId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const AppScaffold(
              title: 'Chat',
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError || snap.data == null) {
            return AppScaffold(
              title: 'Chat',
              body: PlaceholderPage(
                title: 'Chat no disponible',
                subtitle: snap.error?.toString() ?? 'No se encontró información del viaje.',
              ),
            );
          }
          final data = snap.data!;
          return _buildScaffold(
            context: context,
            driverName: data.driverName,
            messages: data.messages,
            readOnly: true,
            tripId: null,
          );
        },
      );
    }

    // Modo activo: suscripción Realtime
    final reserva = ref.watch(reservaProvider);
    final conductor = reserva.conductorSeleccionado;
    final tripId = conductor?.tripId;

    if (conductor == null || tripId == null || tripId.isEmpty) {
      return const AppScaffold(
        title: 'Chat',
        body: PlaceholderPage(
          title: 'Chat no disponible',
          subtitle: 'No se encontró información del viaje.',
        ),
      );
    }

    // Inicializar Realtime la primera vez
    if (_activeTripId == null) {
      _driverName = conductor.name;
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _initRealtime(tripId),
      );
    }

    return _buildScaffold(
      context: context,
      driverName: _driverName ?? conductor.name,
      messages: _messages,
      readOnly: false,
      tripId: tripId,
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required String driverName,
    required List<_ChatEntry> messages,
    required bool readOnly,
    required String? tripId,
  }) {
    final initials = _initials(driverName);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryTint12,
              child: Text(
                initials,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(driverName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (readOnly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.seatWarnBg,
                child: Text(
                  'Chat de solo lectura',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_errorMsg != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.error.withValues(alpha: 0.10),
                child: Text(
                  _errorMsg!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  child: Text(
                    readOnly
                        ? 'No hubo mensajes en este viaje.'
                        : 'Aún no hay mensajes. ¡Saluda al conductor!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(AppSpacing.p20),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MessageBubble(message: m),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      enabled: !readOnly && !_sending,
                      decoration: const InputDecoration(labelText: 'Mensaje'),
                      onSubmitted: readOnly || tripId == null
                          ? null
                          : (_) => _send(tripId),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(56, AppSpacing.controlHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                    ),
                    onPressed: readOnly || tripId == null || _sending
                        ? null
                        : () => _send(tripId),
                    child: _sending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}

// ─── Bubble ──────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatEntry message;

  @override
  Widget build(BuildContext context) {
    final isDriver = message.isDriver;
    final bubbleColor = isDriver ? AppColors.fieldFill : AppColors.primaryBlue;
    final textColor = isDriver ? AppColors.textPrimary : AppColors.white;
    final align = isDriver ? Alignment.centerLeft : Alignment.centerRight;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.r16),
      topRight: const Radius.circular(AppRadius.r16),
      bottomLeft: Radius.circular(isDriver ? AppRadius.r8 : AppRadius.r16),
      bottomRight: Radius.circular(isDriver ? AppRadius.r16 : AppRadius.r8),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Column(
          crossAxisAlignment:
          isDriver ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
                border: isDriver ? Border.all(color: AppColors.border) : null,
              ),
              child: Text(
                message.text,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: textColor),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message.time,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modo readonly: carga histórica ──────────────────────────────────────────

class _ReadonlyChatData {
  const _ReadonlyChatData({required this.driverName, required this.messages});

  final String driverName;
  final List<_ChatEntry> messages;
}

Future<_ReadonlyChatData?> _loadReadonlyChatData(String? reservationId) async {
  if (reservationId == null || reservationId.trim().isEmpty) return null;

  final reservation = await Supabase.instance.client
      .from('reservations')
      .select('''
        id,
        trip_id,
        trips (
          drivers (
            profiles (
              name,
              first_name,
              last_name
            )
          )
        )
      ''')
      .eq('id', reservationId)
      .maybeSingle();

  if (reservation == null) return null;
  final rm = Map<String, dynamic>.from(reservation);
  final tripId = rm['trip_id']?.toString();
  if (tripId == null || tripId.isEmpty) return null;

  final trip = rm['trips'] is Map
      ? Map<String, dynamic>.from(rm['trips'] as Map)
      : <String, dynamic>{};
  final driver = trip['drivers'] is Map
      ? Map<String, dynamic>.from(trip['drivers'] as Map)
      : <String, dynamic>{};
  final profile = driver['profiles'] is Map
      ? Map<String, dynamic>.from(driver['profiles'] as Map)
      : <String, dynamic>{};

  final firstName = profile['first_name']?.toString().trim() ?? '';
  final lastName = profile['last_name']?.toString().trim() ?? '';
  final fullName = '$firstName $lastName'.trim();
  final driverName =
  (profile['name']?.toString().trim().isNotEmpty ?? false)
      ? profile['name'].toString().trim()
      : (fullName.isNotEmpty ? fullName : 'Conductor');

  final rows = await Supabase.instance.client
      .from('trip_messages')
      .select('id, sender_role, message, body, created_at')
      .eq('trip_id', tripId)
      .order('created_at', ascending: true);

  final messages = (rows as List)
      .cast<Map<String, dynamic>>()
      .map(
        (row) {
      final text = row['message']?.toString().trim().isNotEmpty == true
          ? row['message'].toString()
          : (row['body']?.toString() ?? '');
      return _ChatEntry(
        id: row['id']?.toString() ?? '',
        isDriver: row['sender_role']?.toString() == 'driver',
        text: text,
        time: _formatRawTime(row['created_at']?.toString()),
      );
    },
  )
      .toList();

  return _ReadonlyChatData(driverName: driverName, messages: messages);
}

// ─── Utilidades ──────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatRawTime(String? raw) {
  final dt = DateTime.tryParse(raw ?? '')?.toLocal();
  if (dt == null) return '--:--';
  return _formatTime(dt);
}