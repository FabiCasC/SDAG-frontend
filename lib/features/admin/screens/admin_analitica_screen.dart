import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../roles/admin/admin_shell_screen.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

final adminAnaliticaResumenProvider = FutureProvider<AdminAnaliticaResumen>((ref) async {
  final trips = await Supabase.instance.client
      .from('trips')
      .select('amount_total')
      .eq('status', 'completado');

  final totalViajes = await Supabase.instance.client
      .from('trips')
      .select('id')
      .count(CountOption.exact);

  final totalPasajeros = await Supabase.instance.client
      .from('reservations')
      .select('id')
      .eq('status', 'activa')
      .count(CountOption.exact);

  final ingresos = (trips as List).cast<Map<String, dynamic>>().fold<double>(
        0,
        (sum, row) => sum + ((row['amount_total'] as num?)?.toDouble() ?? 0),
      );

  return AdminAnaliticaResumen(
    ingresosTotales: ingresos,
    totalViajes: totalViajes.count,
    totalPasajeros: totalPasajeros.count,
  );
});

class AdminAnaliticaResumen {
  const AdminAnaliticaResumen({
    required this.ingresosTotales,
    required this.totalViajes,
    required this.totalPasajeros,
  });

  final double ingresosTotales;
  final int totalViajes;
  final int totalPasajeros;
}

class AdminAnaliticaScreen extends ConsumerWidget {
  const AdminAnaliticaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pageBg = Color(0xFFF8FAFC);
    final resumenAsync = ref.watch(adminAnaliticaResumenProvider);

    return AdminShellScreen(
      currentRoute: AppRoutes.adminAnalitica,
      title: 'Analítica',
      backgroundColor: pageBg,
      actions: [
        IconButton(
          onPressed: () => ref.refresh(adminAnaliticaResumenProvider),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Recargar',
        ),
      ],
      body: resumenAsync.when(
        data: (resumen) => ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            Text(
              'Estadísticas generales',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              children: [
                _StatCard(
                  title: 'Total ingresos',
                  value: 'S/ ${_formatMoney(resumen.ingresosTotales)}',
                  icon: Icons.attach_money_rounded,
                  color: const Color(0xFF16A34A),
                ),
                _StatCard(
                  title: 'Total viajes',
                  value: '${resumen.totalViajes}',
                  icon: Icons.route_rounded,
                  color: const Color(0xFF2563EB),
                ),
                _StatCard(
                  title: 'Total pasajeros',
                  value: '${resumen.totalPasajeros}',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFFF97316),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoBox(
              text: 'Los ingresos consideran viajes con estado completado y los pasajeros activos se cuentan desde reservations.',
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
                  'No se pudieron cargar las estadísticas.',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1E3A8A),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _formatMoney(double value) {
  final rounded = value.toStringAsFixed(2);
  final parts = rounded.split('.');
  final integer = parts.first;
  final decimals = parts.last;
  final buffer = StringBuffer();
  for (var i = 0; i < integer.length; i++) {
    final fromEnd = integer.length - i;
    buffer.write(integer[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${buffer.toString()}.$decimals';
}
