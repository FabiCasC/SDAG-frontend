import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_conductores_provider.dart';
import '../providers/admin_pagos_provider.dart';

final adminPerfilProvider = StateNotifierProvider<AdminPerfilController, AdminPerfilState>(
  (ref) => AdminPerfilController(),
);

class AdminPerfilState {
  const AdminPerfilState({
    required this.savedEmail,
    required this.savedPhone,
    required this.draftEmail,
    required this.draftPhone,
    required this.loading,
    required this.saving,
  });

  final String savedEmail;
  final String savedPhone;
  final String draftEmail;
  final String draftPhone;
  final bool loading;
  final bool saving;

  bool get hasChanges => savedEmail != draftEmail || savedPhone != draftPhone;

  bool get phoneValid => RegExp(r'^\d{9}$').hasMatch(draftPhone.trim());
  bool get emailValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(draftEmail.trim());
  bool get isValid => phoneValid && emailValid;

  AdminPerfilState copyWith({
    String? savedEmail,
    String? savedPhone,
    String? draftEmail,
    String? draftPhone,
    bool? loading,
    bool? saving,
  }) {
    return AdminPerfilState(
      savedEmail: savedEmail ?? this.savedEmail,
      savedPhone: savedPhone ?? this.savedPhone,
      draftEmail: draftEmail ?? this.draftEmail,
      draftPhone: draftPhone ?? this.draftPhone,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
    );
  }

  static const initial = AdminPerfilState(
    savedEmail: '',
    savedPhone: '',
    draftEmail: '',
    draftPhone: '',
    loading: true,
    saving: false,
  );
}

enum AdminPasswordUpdateResult { ok, invalidCurrent, tooShort, mismatch }

class AdminPerfilController extends StateNotifier<AdminPerfilState> {
  AdminPerfilController() : super(AdminPerfilState.initial) {
    _load();
  }

  static const _emailKey = 'sdag_admin_profile_email';
  static const _phoneKey = 'sdag_admin_profile_phone';
  static const _passwordOverrideKey = 'sdag_admin_password_override';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey) ?? MockData.adminEmail;
    final phone = prefs.getString(_phoneKey) ?? '999999999';
    state = state.copyWith(
      savedEmail: email,
      savedPhone: phone,
      draftEmail: email,
      draftPhone: phone,
      loading: false,
    );
  }

  void setDraftEmail(String v) {
    state = state.copyWith(draftEmail: v);
  }

  void setDraftPhone(String v) {
    state = state.copyWith(draftPhone: v);
  }

  Future<void> save() async {
    if (!state.isValid) return;
    state = state.copyWith(saving: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, state.draftEmail.trim());
    await prefs.setString(_phoneKey, state.draftPhone.trim());
    state = state.copyWith(
      savedEmail: state.draftEmail.trim(),
      savedPhone: state.draftPhone.trim(),
      saving: false,
    );
  }

  Future<AdminPasswordUpdateResult> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expected = prefs.getString(_passwordOverrideKey) ?? MockData.adminPassword;
    if (currentPassword.trim() != expected) return AdminPasswordUpdateResult.invalidCurrent;
    if (newPassword.trim().length < 8) return AdminPasswordUpdateResult.tooShort;
    if (newPassword.trim() != confirmPassword.trim()) return AdminPasswordUpdateResult.mismatch;
    await prefs.setString(_passwordOverrideKey, newPassword.trim());
    return AdminPasswordUpdateResult.ok;
  }
}

class AdminPerfilScreen extends ConsumerStatefulWidget {
  const AdminPerfilScreen({super.key});

  @override
  ConsumerState<AdminPerfilScreen> createState() => _AdminPerfilScreenState();
}

class _AdminPerfilScreenState extends ConsumerState<AdminPerfilScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final ProviderSubscription<AdminPerfilState> _sub;
  bool _didSyncOnce = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _sub = ref.listenManual<AdminPerfilState>(
      adminPerfilProvider,
      (prev, next) {
        if (_didSyncOnce) return;
        if (next.loading) return;
        _didSyncOnce = true;
        _phoneController.text = next.draftPhone;
        _emailController.text = next.draftEmail;
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _sub.close();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _openPasswordSheet() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.p20,
            right: AppSpacing.p20,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cambiar contraseña',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña (mín. 8 caracteres)'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                ),
                onPressed: () async {
                  final result = await ref.read(adminPerfilProvider.notifier).updatePassword(
                        currentPassword: currentController.text,
                        newPassword: newController.text,
                        confirmPassword: confirmController.text,
                      );
                  if (!context.mounted) return;
                  switch (result) {
                    case AdminPasswordUpdateResult.ok:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text('Contraseña actualizada'),
                        ),
                      );
                      Navigator.of(context).pop();
                      return;
                    case AdminPasswordUpdateResult.invalidCurrent:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text('Contraseña actual incorrecta'),
                        ),
                      );
                      return;
                    case AdminPasswordUpdateResult.tooShort:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text('La nueva contraseña debe tener al menos 8 caracteres'),
                        ),
                      );
                      return;
                    case AdminPasswordUpdateResult.mismatch:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text('Las contraseñas no coinciden'),
                        ),
                      );
                      return;
                  }
                },
                child: const Text('Actualizar contraseña'),
              ),
            ],
          ),
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Future<void> _confirmLogout(int pendientes) async {
    final title = pendientes > 0 ? 'Tienes pagos pendientes' : 'Cerrar sesión';
    final content = pendientes > 0
        ? 'Tienes $pendientes solicitudes de pago sin revisar.\n¿Seguro que deseas cerrar sesión?'
        : '¿Seguro que quieres cerrar sesión?';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(pendientes > 0 ? 'Cerrar sesión de todas formas' : 'Cerrar sesión'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;

    ref.invalidate(adminAuthProvider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sdag_admin_logged_in');
    await prefs.remove('sdag_admin_failed_attempts');
    await prefs.remove('sdag_admin_blocked_until_ms');
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final s = ref.watch(adminPerfilProvider);
    final conductores = ref.watch(adminConductoresProvider).listaConductores;
    final pagos = ref.watch(adminPagosProvider);
    final pendientes = pagos.solicitudesPendientes.length;

    final initials = _adminInitials(MockData.adminNombre);
    final name = MockData.adminNombre.replaceAll('Sr. ', '').trim();

    final phoneError = s.loading || s.phoneValid ? null : 'Teléfono inválido (9 dígitos)';
    final emailError = s.loading || s.emailValid ? null : 'Correo inválido';

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Perfil'),
      ),
      body: s.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.p20),
              children: [
                Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
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
                      name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'ADMINISTRADOR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.savedEmail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF62748E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          errorText: phoneError,
                        ),
                        onChanged: (v) => ref.read(adminPerfilProvider.notifier).setDraftPhone(v),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo',
                          errorText: emailError,
                        ),
                        onChanged: (v) => ref.read(adminPerfilProvider.notifier).setDraftEmail(v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton(
                        onPressed: _openPasswordSheet,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                        ),
                        child: const Text('Cambiar contraseña'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _Card(
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  shadow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoRow(label: 'Versión de la app', value: '1.0.0'),
                      _InfoRow(label: 'Última actualización', value: '13/05/2025'),
                      _InfoRow(label: 'Conductores registrados', value: '${conductores.length}'),
                      _InfoRow(label: 'Viajes totales', value: '${MockData.adminStats.viajesMes}'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                  ),
                  onPressed: (!s.hasChanges || !s.isValid || s.saving)
                      ? null
                      : () async {
                          await ref.read(adminPerfilProvider.notifier).save();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Perfil actualizado'),
                            ),
                          );
                        },
                  child: const Text('Guardar cambios'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => _confirmLogout(pendientes),
                  child: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.shadow = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: !shadow
            ? null
            : const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: AppSpacing.shadowBlur,
                  offset: Offset(0, AppSpacing.shadowOffsetY),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

String _adminInitials(String fullName) {
  final clean = fullName.replaceAll('Sr.', '').replaceAll('Sra.', '').trim();
  final parts = clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '—';
  String firstChar(String s) => s.characters.first.toUpperCase();
  if (parts.length == 1) return firstChar(parts[0]);
  return '${firstChar(parts[0])}${firstChar(parts[1])}';
}

