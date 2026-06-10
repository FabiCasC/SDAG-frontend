import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../roles/admin/admin_shell_screen.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

final adminVehiculosProvider = FutureProvider<List<AdminVehiculoItem>>((ref) async {
  final vehicles = await Supabase.instance.client
      .from('vehicles')
      .select('*, drivers(*, profiles(name))')
      .order('created_at', ascending: false);

  return (vehicles as List)
      .cast<Map<String, dynamic>>()
      .map(AdminVehiculoItem.fromMap)
      .toList(growable: false);
});

class AdminVehiculoItem {
  const AdminVehiculoItem({
    required this.id,
    required this.placa,
    required this.tipo,
    required this.capacidad,
    required this.activo,
    required this.conductorAsignado,
  });

  final String id;
  final String placa;
  final String tipo;
  final int capacidad;
  final bool activo;
  final String conductorAsignado;

  factory AdminVehiculoItem.fromMap(Map<String, dynamic> map) {
    final driver = map['drivers'] as Map<String, dynamic>?;
    final profile = driver?['profiles'] as Map<String, dynamic>?;

    return AdminVehiculoItem(
      id: map['id']?.toString() ?? '',
      placa: map['plate']?.toString() ?? 'Sin placa',
      tipo: map['vehicle_type']?.toString() ?? 'No definido',
      capacidad: (map['total_seats'] as num?)?.toInt() ?? 0,
      activo: (map['active'] as bool?) ?? true,
      conductorAsignado: _driverName(profile),
    );
  }
}

class AdminVehiculosScreen extends ConsumerWidget {
  const AdminVehiculosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFFF8FAFC);
    final vehiclesAsync = ref.watch(adminVehiculosProvider);

    return AdminShellScreen(
      currentRoute: AppRoutes.adminVehiculos,
      title: 'Vehículos',
      backgroundColor: bg,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.adminVehiculosNuevo),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Nuevo vehículo',
        ),
      ],
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(
              child: Text('No hay vehículos registrados.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.p20),
            itemCount: vehicles.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _VehiculoCard(item: vehicles[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No se pudieron cargar los vehículos.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.refresh(adminVehiculosProvider),
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

class _VehiculoCard extends StatelessWidget {
  const _VehiculoCard({required this.item});

  final AdminVehiculoItem item;

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipText) = item.activo
        ? (const Color(0xFF16A34A), 'Activo')
        : (const Color(0xFF94A3B8), 'Inactivo');

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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.placa,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
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
                  chipText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: 'Tipo', value: item.tipo),
          const SizedBox(height: 6),
          _InfoRow(label: 'Capacidad', value: '${item.capacidad} asientos'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Conductor', value: item.conductorAsignado),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

String _driverName(Map<String, dynamic>? profile) {
  final raw = profile?['name']?.toString().trim() ?? '';
  return raw.isEmpty ? 'Sin asignar' : raw;
}
