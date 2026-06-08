import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_chat_provider.dart';
import '../providers/conductor_manifiesto_provider.dart';

class ConductorChatScreen extends ConsumerStatefulWidget {
  const ConductorChatScreen({required this.pasajeroId, super.key});

  final String pasajeroId;

  @override
  ConsumerState<ConductorChatScreen> createState() => _ConductorChatScreenState();
}

class _ConductorChatScreenState extends ConsumerState<ConductorChatScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(conductorChatProvider.notifier).sendMessage(
          passengerId: widget.pasajeroId,
          fromConductor: true,
          text: text,
        );
  }

  Future<void> _sendAlternativePickup() async {
    final tc = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.p20,
            right: AppSpacing.p20,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enviar punto alternativo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: tc,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Punto alternativo',
                  hintText: 'Ej: Entrada principal, al lado del grifo...',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCriticalButton(
                label: 'Enviar',
                onPressed: () => Navigator.of(context).pop(tc.text),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    final text = result?.trim();
    if (text == null || text.isEmpty) return;
    await ref.read(conductorChatProvider.notifier).sendAlternativePickup(
          passengerId: widget.pasajeroId,
          text: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final chatCtrl = ref.read(conductorChatProvider.notifier);
    final messages = ref.watch(conductorChatProvider.select((m) => m[widget.pasajeroId])) ??
        chatCtrl.messagesFor(widget.pasajeroId);

    final manifiesto = ref.watch(conductorManifiestoProvider).listaPasajeros;
    final passenger = manifiesto
        .where((p) => p.id == widget.pasajeroId)
        .cast<ManifiestoItem?>()
        .firstWhere((p) => p != null, orElse: () => null);

    final name = passenger?.nombreCompleto ?? 'Pasajero';
    final initials = _initialsFromFullName(name);
    final status = passenger?.estado ?? ManifiestoEstadoPasajero.pendiente;
    final (chipBg, chipFg, chipLabel) = switch (status) {
      ManifiestoEstadoPasajero.subio => (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Abordó'),
      ManifiestoEstadoPasajero.noSubio => (const Color(0xFFFEE2E2), const Color(0xFFDC2626), 'No abordó'),
      ManifiestoEstadoPasajero.pendiente => (const Color(0xFFFEF9C3), const Color(0xFFD97706), 'Pendiente'),
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryTint12,
              child: Text(
                initials,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      chipLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: chipFg,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _sendAlternativePickup,
            icon: const Icon(Icons.edit_location_alt_rounded),
            tooltip: 'Enviar punto alternativo',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.p20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ChatBubble(message: m),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.sm, AppSpacing.p20, AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border.withAlpha(120))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                    ),
                    onPressed: _send,
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ConductorChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isConductor = message.isConductor;
    final bg = isConductor ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9);
    final fg = isConductor ? AppColors.white : const Color(0xFF314158);
    final align = isConductor ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isConductor ? 14 : 4),
      bottomRight: Radius.circular(isConductor ? 4 : 14),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          crossAxisAlignment: isConductor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radius,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF62748E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _initialsFromFullName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'P';
  if (parts.length == 1) {
    final p = parts.first;
    return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
  }
  return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
}

