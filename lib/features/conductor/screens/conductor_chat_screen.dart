import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_chat_provider.dart';
import '../providers/conductor_manifiesto_provider.dart';
import '../providers/conductor_viaje_provider.dart';

class ConductorChatScreen extends ConsumerStatefulWidget {
  const ConductorChatScreen({required this.pasajeroId, super.key});

  /// `passenger_profile_id` del pasajero.
  final String pasajeroId;

  @override
  ConsumerState<ConductorChatScreen> createState() => _ConductorChatScreenState();
}

class _ConductorChatScreenState extends ConsumerState<ConductorChatScreen> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  int _lastMessageCount = -1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      _controller.clear();
      final tripId = ref.read(conductorViajeProvider).tripId ?? '';
      final key = '$tripId|${widget.pasajeroId}';
      await ref.read(conductorTripChatProvider(key).notifier).sendMessage(text);
    } catch (e) {
      if (!mounted) return;
      _controller.text = text;
      AppSnackbars.error(context, e.toString());
    }
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
    try {
      final tripId = ref.read(conductorViajeProvider).tripId ?? '';
      final key = '$tripId|${widget.pasajeroId}';
      await ref.read(conductorTripChatProvider(key).notifier).sendAlternativePickup(text);
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, e.toString());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viaje = ref.watch(conductorViajeProvider);
    final tripId = viaje.tripId;

    if (widget.pasajeroId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Chat'),
        ),
        body: const Center(child: Text('Pasajero no válido.')),
      );
    }

    if (tripId == null || tripId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Chat'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.p20),
            child: Text(
              'No hay un viaje activo. Abre el chat desde la gestión del viaje cuando tengas un trip en curso.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final chatKey = '$tripId|${widget.pasajeroId}';
    final chatState = ref.watch(conductorTripChatProvider(chatKey));

    final n = chatState.messages.length;
    if (n != _lastMessageCount) {
      _lastMessageCount = n;
      _scrollToBottom();
    }

    final manifiesto = ref.watch(conductorManifiestoProvider).listaPasajeros;
    ManifiestoItem? passenger;
    for (final p in manifiesto) {
      if (p.id == widget.pasajeroId) {
        passenger = p;
        break;
      }
    }

    PasajeroViaje? viajePasajero;
    for (final p in viaje.pasajerosViaje) {
      if (p.profileId == widget.pasajeroId) {
        viajePasajero = p;
        break;
      }
    }

    final name = passenger?.nombreCompleto ?? viajePasajero?.nombre ?? 'Pasajero';

    final messages = chatState.messages;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
          if (chatState.errorMessage != null && messages.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  child: Text(
                    chatState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: chatState.loading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
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

  final ConductorTripChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isConductor = message.isFromDriver;
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
