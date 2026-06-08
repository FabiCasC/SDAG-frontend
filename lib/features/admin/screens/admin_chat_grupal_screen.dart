import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../conductor/providers/conductor_chat_grupal_provider.dart';

class AdminChatGrupalScreen extends ConsumerStatefulWidget {
  const AdminChatGrupalScreen({super.key});

  @override
  ConsumerState<AdminChatGrupalScreen> createState() => _AdminChatGrupalScreenState();
}

class _AdminChatGrupalScreenState extends ConsumerState<AdminChatGrupalScreen> {
  static const _adminPlate = 'ADMIN';
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
    await ref.read(conductorChatGrupalProvider.notifier).send(
          senderName: MockData.adminNombre,
          senderPlate: _adminPlate,
          text: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conductorChatGrupalProvider);
    final messages = state.messages;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Expanded(child: Text('Chat grupal (Admin + conductores)')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withAlpha(26),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${state.online.length} online',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20, vertical: AppSpacing.sm),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                const Icon(Icons.info_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Canal general para coordinación con todos los conductores',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.p20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final isMe = m.senderPlate == _adminPlate;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _GroupBubble(message: m, isMe: isMe),
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

class _GroupBubble extends StatelessWidget {
  const _GroupBubble({required this.message, required this.isMe});

  final ConductorGroupMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9);
    final fg = isMe ? AppColors.white : const Color(0xFF314158);
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMe ? 14 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 14),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${message.senderName} (${message.senderPlate})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
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
