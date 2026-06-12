import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_navigation_back.dart';

final adminPerfilProvider = FutureProvider<AdminPerfilData>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    throw StateError('No hay una sesión activa.');
  }

  final profile = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return AdminPerfilData.fromMap(profile, fallbackEmail: user.email);
});

class AdminPerfilData {
  const AdminPerfilData({
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
  });

  final String nombre;
  final String email;
  final String telefono;
  final String rol;

  factory AdminPerfilData.fromMap(
    Map<String, dynamic> map, {
    String? fallbackEmail,
  }) {
    final firstName = map['first_name']?.toString().trim() ?? '';
    final lastName = map['last_name']?.toString().trim() ?? '';
    final combinedName = '$firstName $lastName'.trim();
    final name = combinedName.isNotEmpty
        ? combinedName
        : (map['name']?.toString().trim().isNotEmpty ?? false)
            ? map['name'].toString().trim()
            : 'Administrador';

    return AdminPerfilData(
      nombre: name,
      email: (map['email']?.toString().trim().isNotEmpty ?? false)
          ? map['email'].toString().trim()
          : (fallbackEmail ?? 'No disponible'),
      telefono: (map['phone']?.toString().trim().isNotEmpty ?? false)
          ? map['phone'].toString().trim()
          : 'No registrado',
      rol: (map['role']?.toString().trim().isNotEmpty ?? false)
          ? map['role'].toString().trim()
          : 'admin',
    );
  }
}

class AdminPerfilScreen extends ConsumerWidget {
  const AdminPerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pageBg = Color(0xFFF8FAFC);
    final perfilAsync = ref.watch(adminPerfilProvider);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        leading: AppBarLeadingBack(fallbackRoute: AppRoutes.adminHome),
        title: const Text('Perfil'),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(adminPerfilProvider),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: perfilAsync.when(
        data: (perfil) => ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            _ProfileHeader(perfil: perfil),
            const SizedBox(height: AppSpacing.md),
            _InfoCard(
              children: [
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Nombre',
                  value: perfil.nombre,
                ),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: perfil.email,
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: perfil.telefono,
                ),
                _InfoTile(
                  icon: Icons.security_outlined,
                  label: 'Rol',
                  value: perfil.rol.toUpperCase(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
              ),
              onPressed: () => context.go(AppRoutes.adminHome),
              child: const Text('Volver al panel'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => _cerrarSesion(context),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFDC2626)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No se pudo cargar el perfil del administrador.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.refresh(adminPerfilProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.perfil});

  final AdminPerfilData perfil;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(perfil.nombre);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.shadowBlur,
            offset: Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.p20),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            perfil.nombre,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              perfil.rol.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'AD';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts[0].characters.first.toUpperCase()}${parts[1].characters.first.toUpperCase()}';
}
