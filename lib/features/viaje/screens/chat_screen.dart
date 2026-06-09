import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/viaje_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qs = GoRouterState.of(context).uri.queryParameters;
    final readonly = qs['readonly'] == '1';
    final tripId = qs['tripId'];

    final activeReserva = ref.watch(reservaProvider);
    final activeViaje = ref.watch(viajeProvider);
    final activeController = ref.read(viajeProvider.notifier);
    if (readonly) {
      return FutureBuilder<_ReadonlyChatData?>(
        future: _loadReadonlyChatData(tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppScaffold(
              title: 'Chat',
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return AppScaffold(
              title: 'Chat',
              body: PlaceholderPage(
                title: 'Chat no disponible',
                subtitle: snapshot.error.toString(),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const AppScaffold(
              title: 'Chat',
              body: PlaceholderPage(
                title: 'Chat no disponible',
                subtitle: 'No se encontró información del viaje.',
              ),
            );
          }

          return _buildChatScaffold(
            context: context,
            driverName: data.driverName,
            messages: data.messages,
            readOnly: true,
            activeController: activeController,
          );
        },
      );
    }

    final driverName = activeReserva.conductorSeleccionado?.name;
    if (driverName == null) {
      return const AppScaffold(
        title: 'Chat',
        body: PlaceholderPage(
          title: 'Chat no disponible',
          subtitle: 'No se encontró información del viaje.',
        ),
      );
    }

    final messages = activeViaje.messages
        .map((m) => _ChatEntry(isDriver: m.isDriver, text: m.text, time: _formatTime(m.timestamp)))
        .toList();

    return _buildChatScaffold(
      context: context,
      driverName: driverName,
      messages: messages,
      readOnly: activeViaje.readOnlyChat,
      activeController: activeController,
    );
  }

  void _send(ViajeController controller, bool readOnly) {
    if (readOnly) return;
    final text = _controller.text;
    controller.sendMessage(text);
    _controller.clear();
  }

  Widget _buildChatScaffold({
    required BuildContext context,
    required String driverName,
    required List<_ChatEntry> messages,
    required bool readOnly,
    required ViajeController activeController,
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
              child: Text(
                driverName,
                overflow: TextOverflow.ellipsis,
              ),
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
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.p20),
                        child: Text(
                          'No hubo mensajes en este viaje.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.p20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final m = messages[index];
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
                      controller: _controller,
                      enabled: !readOnly,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje',
                      ),
                      onSubmitted: (_) => _send(activeController, readOnly),
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
                    onPressed: readOnly ? null : () => _send(activeController, false),
                    child: const Icon(Icons.send_rounded),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatEntry message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    final time = message.time;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Column(
          crossAxisAlignment: isDriver ? CrossAxisAlignment.start : CrossAxisAlignment.end,
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
                style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              time,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEntry {
  const _ChatEntry({required this.isDriver, required this.text, required this.time});

  final bool isDriver;
  final String text;
  final String time;
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
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

  final reservationMap = Map<String, dynamic>.from(reservation);
  final tripId = reservationMap['trip_id']?.toString();
  if (tripId == null || tripId.isEmpty) return null;

  final trip = reservationMap['trips'] is Map ? Map<String, dynamic>.from(reservationMap['trips'] as Map) : <String, dynamic>{};
  final driver = trip['drivers'] is Map ? Map<String, dynamic>.from(trip['drivers'] as Map) : <String, dynamic>{};
  final profile = driver['profiles'] is Map ? Map<String, dynamic>.from(driver['profiles'] as Map) : <String, dynamic>{};
  final firstName = profile['first_name']?.toString().trim() ?? '';
  final lastName = profile['last_name']?.toString().trim() ?? '';
  final fullName = '$firstName $lastName'.trim();
  final driverName = (profile['name']?.toString().trim().isNotEmpty ?? false)
      ? profile['name'].toString().trim()
      : (fullName.isNotEmpty ? fullName : 'Conductor');

  final rows = await Supabase.instance.client
      .from('trip_messages')
      .select('id, sender_role, body, created_at')
      .eq('trip_id', tripId)
      .order('created_at', ascending: true);

  final messages = (rows as List)
      .cast<Map<String, dynamic>>()
      .map(
        (row) => _ChatEntry(
          isDriver: row['sender_role']?.toString() == 'driver',
          text: row['body']?.toString() ?? '',
          time: _formatRawTime(row['created_at']?.toString()),
        ),
      )
      .toList();

  return _ReadonlyChatData(
    driverName: driverName,
    messages: messages,
  );
}

String _formatRawTime(String? raw) {
  final dt = DateTime.tryParse(raw ?? '')?.toLocal();
  if (dt == null) return '--:--';
  return _formatTime(dt);
}

class _ReadonlyChatData {
  const _ReadonlyChatData({
    required this.driverName,
    required this.messages,
  });

  final String driverName;
  final List<_ChatEntry> messages;
}
