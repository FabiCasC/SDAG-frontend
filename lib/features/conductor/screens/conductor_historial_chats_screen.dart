import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/app_navigation_back.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class ConductorHistorialChatsScreen extends ConsumerStatefulWidget {
  const ConductorHistorialChatsScreen({super.key});

  @override
  ConsumerState<ConductorHistorialChatsScreen> createState() =>
      _ConductorHistorialChatsScreenState();
}

class _ConductorHistorialChatsScreenState
    extends ConsumerState<ConductorHistorialChatsScreen> {
  bool _loading = true;
  String? _error;
  List<_ArchivedTripChat> _chats = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'Sesión inválida';
        });
        return;
      }

      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      final driverId = driver?['id']?.toString();
      if (driverId == null) {
        setState(() {
          _loading = false;
          _error = 'No se encontró el conductor';
        });
        return;
      }

      final since = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

      final trips = await Supabase.instance.client
          .from('trips')
          .select('id, status, finished_at, routes(name, from_label, to_label)')
          .eq('driver_id', driverId)
          .eq('status', 'completado')
          .gte('finished_at', since)
          .order('finished_at', ascending: false);

      final result = <_ArchivedTripChat>[];

      for (final raw in (trips as List).cast<Map<String, dynamic>>()) {
        final tripId = raw['id']?.toString();
        if (tripId == null) continue;

        final messages = await Supabase.instance.client
            .from('trip_messages')
            .select('id, body, sender_role, message_type, created_at, message_status')
            .eq('trip_id', tripId)
            .eq('message_status', 'archivado')
            .order('created_at', ascending: true);

        if ((messages as List).isEmpty) continue;

        final route = raw['routes'] is Map
            ? Map<String, dynamic>.from(raw['routes'] as Map)
            : null;
        final routeLabel = route?['name']?.toString().trim().isNotEmpty == true
            ? route!['name'].toString()
            : '${route?['from_label'] ?? ''} → ${route?['to_label'] ?? ''}';

        result.add(
          _ArchivedTripChat(
            tripId: tripId,
            routeLabel: routeLabel.trim().isEmpty ? 'Viaje' : routeLabel,
            finishedAt: DateTime.tryParse(raw['finished_at']?.toString() ?? ''),
            messages: (messages as List)
                .map((m) => _ArchivedMessage.fromMap(Map<String, dynamic>.from(m as Map)))
                .toList(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _chats = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: AppBarLeadingBack(fallbackRoute: AppRoutes.driverHome),
        title: const Text('Historial de chats'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? PlaceholderPage(title: 'Error', subtitle: _error!)
              : _chats.isEmpty
                  ? const PlaceholderPage(
                      title: 'Sin chats archivados',
                      subtitle:
                          'Los mensajes de viajes completados en los últimos 7 días aparecerán aquí.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.p20),
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AppCard(
                            child: ExpansionTile(
                              title: Text(
                                chat.routeLabel,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              subtitle: Text(
                                '${chat.messages.length} mensajes · ${_formatDate(chat.finishedAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              children: chat.messages
                                  .map(
                                    (m) => ListTile(
                                      dense: true,
                                      title: Text(m.body),
                                      subtitle: Text(
                                        '${m.senderRole} · ${_formatDate(m.createdAt)}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ArchivedTripChat {
  const _ArchivedTripChat({
    required this.tripId,
    required this.routeLabel,
    required this.finishedAt,
    required this.messages,
  });

  final String tripId;
  final String routeLabel;
  final DateTime? finishedAt;
  final List<_ArchivedMessage> messages;
}

class _ArchivedMessage {
  const _ArchivedMessage({
    required this.body,
    required this.senderRole,
    required this.createdAt,
  });

  final String body;
  final String senderRole;
  final DateTime? createdAt;

  factory _ArchivedMessage.fromMap(Map<String, dynamic> map) {
    return _ArchivedMessage(
      body: map['body']?.toString() ?? '',
      senderRole: map['sender_role']?.toString() ?? '—',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}
