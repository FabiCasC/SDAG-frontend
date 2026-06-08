import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_auth_provider.dart';

class AdminBloqueadoScreen extends ConsumerStatefulWidget {
  const AdminBloqueadoScreen({super.key});

  @override
  ConsumerState<AdminBloqueadoScreen> createState() => _AdminBloqueadoScreenState();
}

class _AdminBloqueadoScreenState extends ConsumerState<AdminBloqueadoScreen> {
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 10);
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _syncRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncRemaining();
      if (_remaining == Duration.zero && !_notified) {
        _notified = true;
        ref.read(adminAuthProvider.notifier).resetIntentos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Ya puedes intentar de nuevo'),
          ),
        );
      }
      if (mounted) setState(() {});
    });
  }

  void _syncRemaining() {
    final auth = ref.read(adminAuthProvider);
    _remaining = auth.tiempoBloqueado;
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 24 * 60 * 60);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _contactarSoporte() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soporte técnico'),
        content: const Text('Contacta al soporte para desbloqueo de cuenta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);
    final remaining = auth.tiempoBloqueado;
    final canRetry = remaining == Duration.zero;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Acceso bloqueado'),
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.adminLogin),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFDC2626),
                  size: 88,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Cuenta bloqueada temporalmente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Vuelve a intentar en:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _format(remaining),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: canRetry ? const Color(0xFF0F172A) : AppColors.border,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
                  onPressed: canRetry ? () => context.go(AppRoutes.adminLogin) : null,
                  child: const Text('Intentar de nuevo'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
                  onPressed: _contactarSoporte,
                  child: const Text('Contactar soporte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
