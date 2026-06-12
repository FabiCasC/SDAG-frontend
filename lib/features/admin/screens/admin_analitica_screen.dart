import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../roles/admin/admin_shell_screen.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

final adminAnaliticaResumenProvider = FutureProvider<AdminAnaliticaResumen>((ref) async {
  final pagos = await Supabase.instance.client
      .from('payments')
      .select('amount, reservations(trip_id, trips(status))')
      .eq('status', 'confirmado');
  final totalIngresos = (pagos as List).cast<Map<String, dynamic>>().fold<double>(0.0, (sum, p) {
    final reservation = p['reservations'];
    final trip = reservation is Map ? reservation['trips'] : null;
    final tripStatus = trip is Map ? trip['status']?.toString() : null;
    if (tripStatus != 'completado') return sum;
    return sum + ((p['amount'] as num?)?.toDouble() ?? 0.0);
  });

  final totalViajes = await Supabase.instance.client
      .from('trips')
      .select('id')
      .eq('status', 'completado')
      .count(CountOption.exact);
  final countViajes = totalViajes.count;

  final viajesEnRuta = await Supabase.instance.client
      .from('trips')
      .select('id')
      .eq('status', 'en_ruta')
      .count(CountOption.exact);
  final countEnRuta = viajesEnRuta.count;

  final totalPasajeros = await Supabase.instance.client
      .from('reservations')
      .select('id')
      .inFilter('status', ['activa', 'completada'])
      .count(CountOption.exact);
  final countPasajeros = totalPasajeros.count;

  final comisiones = await Supabase.instance.client
      .from('driver_commissions')
      .select('comision');
  final totalComisiones = (comisiones as List).cast<Map<String, dynamic>>().fold<double>(
        0.0,
        (sum, c) => sum + ((c['comision'] as num?)?.toDouble() ?? 0.0),
      );

  final conductores = await Supabase.instance.client
      .from('trips')
      .select('driver_id, drivers(profiles(name))')
      .eq('status', 'completado');

  String? conductorTop;
  final conteoConductores = <String, ({String name, int count})>{};
  for (final row in (conductores as List).cast<Map<String, dynamic>>()) {
    final driverId = row['driver_id']?.toString();
    final driver = row['drivers'] as Map<String, dynamic>?;
    final profile = driver?['profiles'] as Map<String, dynamic>?;
    final name = profile?['name']?.toString().trim();
    if (driverId == null || driverId.isEmpty) continue;
    final actual = conteoConductores[driverId];
    conteoConductores[driverId] = (
      name: (name == null || name.isEmpty) ? 'Conductor' : name,
      count: (actual?.count ?? 0) + 1,
    );
  }
  if (conteoConductores.isNotEmpty) {
    final top = conteoConductores.values.reduce((a, b) => a.count >= b.count ? a : b);
    conductorTop = '${top.name} (${top.count})';
  }

  return AdminAnaliticaResumen(
    ingresosTotales: totalIngresos,
    totalViajes: countViajes,
    viajesEnRuta: countEnRuta,
    totalPasajeros: countPasajeros,
    totalComisiones: totalComisiones,
    conductorTop: conductorTop,
  );
});

class AdminAnaliticaResumen {
  const AdminAnaliticaResumen({
    required this.ingresosTotales,
    required this.totalViajes,
    required this.viajesEnRuta,
    required this.totalPasajeros,
    required this.totalComisiones,
    required this.conductorTop,
  });

  final double ingresosTotales;
  final int totalViajes;
  final int viajesEnRuta;
  final int totalPasajeros;
  final double totalComisiones;
  final String? conductorTop;
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
                  title: 'Viajes completados',
                  value: '${resumen.totalViajes}',
                  icon: Icons.route_rounded,
                  color: const Color(0xFF2563EB),
                ),
                _StatCard(
                  title: 'Viajes en curso',
                  value: '${resumen.viajesEnRuta}',
                  icon: Icons.alt_route_rounded,
                  color: const Color(0xFFEA580C),
                ),
                _StatCard(
                  title: 'Total pasajeros',
                  value: '${resumen.totalPasajeros}',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFFF97316),
                ),
                _StatCard(
                  title: 'Total comisiones',
                  value: 'S/ ${_formatMoney(resumen.totalComisiones)}',
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (resumen.conductorTop != null)
              _InfoBox(
                text: 'Conductor con más viajes: ${resumen.conductorTop}',
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
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.refresh(adminAnaliticaResumenProvider),
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
