import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../roles/admin/admin_shell_screen.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';

class AdminConductoresScreen extends ConsumerWidget {
  const AdminConductoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFFF8FAFC);

    final state = ref.watch(adminConductoresProvider);
    final controller = ref.read(adminConductoresProvider.notifier);
    final items = state.listaFiltrada;

    return AdminShellScreen(
      currentRoute: AppRoutes.adminConductores,
      title: 'Conductores',
      backgroundColor: bg,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.adminConductoresNuevo),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Nuevo conductor',
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.p20, AppSpacing.p20, AppSpacing.sm),
            child: TextField(
              onChanged: controller.buscarConductor,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o placa...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No se encontraron conductores'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.p20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final c = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ConductorCard(
                          conductor: c,
                          onTap: () => context.push('/admin/conductores/${c.id}'),
                          onVerPerfil: () => context.push('/admin/conductores/${c.id}'),
                          onEditar: () => context.push('/admin/conductores/${c.id}/editar'),
                          onVerHistorial: () => context.push('/admin/conductores/${c.id}/historial'),
                          onDesactivar: () async {
                            try {
                              await controller.desactivarConductor(c.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('Conductor desactivado correctamente'),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.error,
                                  content: Text('No se pudo desactivar'),
                                ),
                              );
                            }
                          },
                          onReactivar: () async {
                            try {
                              await controller.reactivarConductor(c.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('Conductor activado correctamente'),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.error,
                                  content: Text('No se pudo reactivar'),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConductorCard extends StatelessWidget {
  const _ConductorCard({
    required this.conductor,
    required this.onTap,
    required this.onVerPerfil,
    required this.onEditar,
    required this.onDesactivar,
    required this.onReactivar,
    required this.onVerHistorial,
  });

  final MockAdminConductor conductor;
  final VoidCallback onTap;
  final VoidCallback onVerPerfil;
  final VoidCallback onEditar;
  final VoidCallback onDesactivar;
  final VoidCallback onReactivar;
  final VoidCallback onVerHistorial;

  @override
  Widget build(BuildContext context) {
    const avatarBg = Color(0xFF1E40AF);
    final initials = _initials(conductor.nombres, conductor.apellidos);
    final (chipBg, chipLabel) = _statusChip(conductor.estado);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppSpacing.shadowBlur,
              offset: Offset(0, AppSpacing.shadowOffsetY),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    conductor.nombreCompleto,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF314158),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    chipLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    conductor.placa,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  conductor.vehiculoTipo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF62748E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${conductor.capacidad} asientos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF62748E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.percent_rounded, size: 18, color: Color(0xFF62748E)),
                const SizedBox(width: 6),
                Text(
                  '${conductor.comisionPorcentaje.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF314158),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: AppSpacing.md),
                _Stars(rating: conductor.ratingPromedio, count: conductor.ratingCount),
                const Spacer(),
                PopupMenuButton<_ConductorMenuAction>(
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                  onSelected: (value) {
                    switch (value) {
                      case _ConductorMenuAction.verPerfil:
                        onVerPerfil();
                        return;
                      case _ConductorMenuAction.editar:
                        onEditar();
                        return;
                      case _ConductorMenuAction.desactivar:
                        onDesactivar();
                        return;
                      case _ConductorMenuAction.reactivar:
                        onReactivar();
                        return;
                      case _ConductorMenuAction.verHistorial:
                        onVerHistorial();
                        return;
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<_ConductorMenuAction>>[
                      const PopupMenuItem(
                        value: _ConductorMenuAction.verPerfil,
                        child: Text('Ver perfil'),
                      ),
                      const PopupMenuItem(
                        value: _ConductorMenuAction.editar,
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: _ConductorMenuAction.verHistorial,
                        child: Text('Ver historial'),
                      ),
                    ];
                    if (conductor.estado == MockAdminConductorEstado.inactivo) {
                      items.insert(
                        2,
                        const PopupMenuItem(
                          value: _ConductorMenuAction.reactivar,
                          child: Text('Reactivar'),
                        ),
                      );
                    } else {
                      items.insert(
                        2,
                        const PopupMenuItem(
                          value: _ConductorMenuAction.desactivar,
                          child: Text('Desactivar'),
                        ),
                      );
                    }
                    return items;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: conductor.estado == MockAdminConductorEstado.inactivo
                  ? FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: onReactivar,
                      child: const Text('Activar'),
                    )
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                      onPressed: onDesactivar,
                      child: const Text('Desactivar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final hasHalf = (rating - full) >= 0.5 && full < 5;
    final stars = <Widget>[];
    for (var i = 0; i < full; i++) {
      stars.add(const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)));
    }
    if (hasHalf) {
      stars.add(const Icon(Icons.star_half_rounded, size: 16, color: Color(0xFFF59E0B)));
    }
    while (stars.length < 5) {
      stars.add(const Icon(Icons.star_border_rounded, size: 16, color: Color(0xFFCBD5E1)));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF62748E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

String _initials(String nombres, String apellidos) {
  String firstLetter(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    return t.characters.first.toUpperCase();
  }

  final n = firstLetter(nombres);
  final a = firstLetter(apellidos);
  final out = '$n$a';
  return out.isEmpty ? '—' : out;
}

(Color, String) _statusChip(MockAdminConductorEstado estado) {
  switch (estado) {
    case MockAdminConductorEstado.enRuta:
      return (const Color(0xFF2563EB), 'En ruta');
    case MockAdminConductorEstado.disponible:
      return (const Color(0xFF16A34A), 'Disponible');
    case MockAdminConductorEstado.inactivo:
      return (const Color(0xFF94A3B8), 'Inactivo');
    case MockAdminConductorEstado.bloqueado:
      return (const Color(0xFFDC2626), 'Bloqueado');
  }
}

enum _ConductorMenuAction { verPerfil, editar, desactivar, reactivar, verHistorial }
