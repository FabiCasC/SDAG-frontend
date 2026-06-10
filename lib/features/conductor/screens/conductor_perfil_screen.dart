import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/conductor_auth_provider.dart';
import '../providers/conductor_voice_provider.dart';
import '../providers/perfil_conductor_provider.dart';

class ConductorPerfilScreen extends ConsumerStatefulWidget {
  const ConductorPerfilScreen({super.key});

  @override
  ConsumerState<ConductorPerfilScreen> createState() => _ConductorPerfilScreenState();
}

class _ConductorPerfilScreenState extends ConsumerState<ConductorPerfilScreen> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openChangePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
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
                'Cambiar contraseña',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña (mín. 6)'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Actualizar'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );

    if (ok != true) return;

    final success = await ref.read(perfilConductorProvider.notifier).updatePassword(
          currentPassword: current.text,
          newPassword: next.text,
          confirmPassword: confirm.text,
        );

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('No se pudo actualizar la contraseña'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Contraseña actualizada'),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final auth = ref.read(conductorAuthProvider);
    if (auth.estadoActual == ConductorEstadoActual.enRuta) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('No puedes cerrar sesión'),
            content: const Text(
              'Estás en ruta activa. No puedes cerrar sesión hasta completar el viaje.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          );
        },
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    ref.invalidate(conductorAuthProvider);
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(conductorAuthProvider);
    final voice = ref.watch(conductorVoiceProvider);
    final perfil = ref.watch(perfilConductorProvider);

    if (_phoneController.text.isEmpty && perfil.telefono.isNotEmpty) {
      _phoneController.text = perfil.telefono;
    }

    final initials = _initials(MockData.conductorNombre);
    final rating = MockData.conductorRatingPromedio;
    final ratingCount = MockData.conductorRatingCount;
    final ratingText =
        ratingCount <= 0 ? 'Sin calificaciones aún' : '${rating.toStringAsFixed(1)} ★ ($ratingCount valoraciones)';

    final accesoChip = auth.accesoOperativo
        ? (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Activo')
        : (const Color(0xFFFEE2E2), const Color(0xFFDC2626), 'Bloqueado');

    final estadoLabel = switch (auth.estadoActual) {
      ConductorEstadoActual.disponible => 'disponible',
      ConductorEstadoActual.activo => 'activo',
      ConductorEstadoActual.enRuta => 'en_ruta',
      ConductorEstadoActual.finalizado => 'finalizado',
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(
                initials,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            MockData.conductorNombre,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'CONDUCTOR',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ratingText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Solo el administrador puede editar estos datos',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _kv(context, 'Placa', MockData.conductorPlaca, muted: true),
                _kv(context, 'Tipo de vehículo', MockData.conductorVehiculo),
                _kv(context, 'Capacidad', '${MockData.conductorCapacidad} asientos'),
                _kv(
                  context,
                  'Porcentaje de comisión',
                  '${(MockData.conductorPorcentajeComision * 100).round()}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Datos editables',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '9 dígitos',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
                  onPressed: () async {
                    final ok = await ref
                        .read(perfilConductorProvider.notifier)
                        .updateTelefono(_phoneController.text);
                    if (!context.mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text('Teléfono inválido (debe tener 9 dígitos)'),
                        ),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Teléfono actualizado'),
                      ),
                    );
                  },
                  child: const Text('Guardar teléfono'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(perfilConductorProvider.notifier).updateFoto();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Foto actualizada'),
                      ),
                    );
                  },
                  child: const Text('Cambiar foto'),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton(
                  onPressed: _openChangePassword,
                  child: const Text('Cambiar contraseña'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Preferencias',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Expanded(child: Text('Notificaciones por voz')),
                    Switch(
                      value: voice.enabled,
                      onChanged: (v) => ref.read(perfilConductorProvider.notifier).toggleVoz(v),
                    ),
                  ],
                ),
                const Divider(height: 1, color: AppColors.border),
                Row(
                  children: [
                    const Expanded(child: Text('Notificaciones push')),
                    Switch(
                      value: perfil.pushEnabled,
                      onChanged: (v) => ref.read(perfilConductorProvider.notifier).togglePush(v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Estado operativo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Expanded(child: Text('Acceso operativo')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: accesoChip.$1,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        accesoChip.$3,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: accesoChip.$2,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                _kv(context, 'Estado actual', estadoLabel),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: _confirmLogout,
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    final p = parts.first;
    return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
  }
  return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
}

Widget _kv(BuildContext context, String k, String v, {bool muted = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Text(
          v,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: muted ? const Color(0xFF64748B) : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    ),
  );
}
