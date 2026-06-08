import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_analitica_provider.dart';

class AdminAnaliticaScreen extends ConsumerStatefulWidget {
  const AdminAnaliticaScreen({super.key});

  @override
  ConsumerState<AdminAnaliticaScreen> createState() => _AdminAnaliticaScreenState();
}

class _AdminAnaliticaScreenState extends ConsumerState<AdminAnaliticaScreen> {
  DateTimeRange? _customRange;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (range == null) return;
    setState(() => _customRange = range);
    ref.read(adminAnaliticaProvider.notifier).filtrarPorPeriodo(
          AdminAnaliticaPeriodo.custom,
          desde: DateTime(range.start.year, range.start.month, range.start.day),
          hasta: DateTime(range.end.year, range.end.month, range.end.day),
        );
  }

  @override
  Widget build(BuildContext context) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final state = ref.watch(adminAnaliticaProvider);
    final controller = ref.read(adminAnaliticaProvider.notifier);
    final stats = state.estadisticas;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Analítica'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          _PeriodSelector(
            selected: state.periodoSeleccionado,
            onSelect: (p) async {
              if (p == AdminAnaliticaPeriodo.custom) {
                await _pickCustomRange();
                return;
              }
              controller.filtrarPorPeriodo(p);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _IndicatorsGrid(stats: stats),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Ingresos diarios (últimos 7 días)',
            child: SizedBox(
              height: 220,
              child: _IngresosBarChart(items: state.ingresosDiarios),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Ocupación por conductor',
            subtitle: 'Ordenado de mayor a menor ocupación',
            child: Column(
              children: [
                for (final r in state.rankingConductores)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _OcupacionRow(item: r),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Desglose por conductor',
            child: _DesgloseTabla(items: state.rankingConductores),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () async {
              await controller.exportarReporte();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text('Reporte generado y guardado'),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
            ),
            child: const Text('Exportar reporte'),
          ),
        ],
      ),
      bottomNavigationBar: const _AdminBottomNav(currentIndex: 4),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onSelect,
  });

  final AdminAnaliticaPeriodo selected;
  final ValueChanged<AdminAnaliticaPeriodo> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PeriodChip(
            label: 'Hoy',
            selected: selected == AdminAnaliticaPeriodo.hoy,
            onTap: () => onSelect(AdminAnaliticaPeriodo.hoy),
          ),
          const SizedBox(width: AppSpacing.sm),
          _PeriodChip(
            label: 'Esta semana',
            selected: selected == AdminAnaliticaPeriodo.semana,
            onTap: () => onSelect(AdminAnaliticaPeriodo.semana),
          ),
          const SizedBox(width: AppSpacing.sm),
          _PeriodChip(
            label: 'Este mes',
            selected: selected == AdminAnaliticaPeriodo.mes,
            onTap: () => onSelect(AdminAnaliticaPeriodo.mes),
          ),
          const SizedBox(width: AppSpacing.sm),
          _PeriodChip(
            label: 'Rango custom',
            selected: selected == AdminAnaliticaPeriodo.custom,
            onTap: () => onSelect(AdminAnaliticaPeriodo.custom),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _IndicatorsGrid extends StatelessWidget {
  const _IndicatorsGrid({required this.stats});

  final AdminAnaliticaStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _IndicatorCard(
          title: 'Ingresos totales',
          value: 'S/ ${_formatNumber(stats.ingresosTotales.round())}',
          color: const Color(0xFF16A34A),
        ),
        _IndicatorCard(
          title: 'Viajes completados',
          value: '${stats.viajesCompletados}',
          color: const Color(0xFF2563EB),
        ),
        _IndicatorCard(
          title: 'Ocupación promedio',
          value: '${(stats.ocupacionPromedio * 100).round()}%',
          color: const Color(0xFFF97316),
        ),
        _IndicatorCard(
          title: 'Comisiones pagadas',
          value: 'S/ ${_formatNumber(stats.comisionesPagadas.round())}',
          color: const Color(0xFF9333EA),
        ),
      ],
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        border: Border(
          left: BorderSide(color: color, width: 6),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
          ),
        ],
      ),
    );
  }
}

class _IngresosBarChart extends StatelessWidget {
  const _IngresosBarChart({required this.items});

  final List<AdminIngresoDiario> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }
    final maxY = items.map((e) => e.monto).fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: (maxY * 1.15).clamp(1, double.infinity),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    items[i].label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < items.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: items[i].monto,
                  color: const Color(0xFF2563EB),
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: const Color(0xFF0F172A),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = items[group.x];
              return BarTooltipItem(
                '${item.label}\nS/ ${item.monto.toStringAsFixed(0)}',
                const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OcupacionRow extends StatelessWidget {
  const _OcupacionRow({required this.item});

  final AdminRankingConductor item;

  @override
  Widget build(BuildContext context) {
    final pct = (item.ocupacion * 100).round();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.nombre} · ${item.placa}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFF97316),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.ocupacion.clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF97316)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recaudado: S/ ${_formatNumber(item.recaudado.round())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                'Comisión: S/ ${_formatNumber(item.comision.round())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9333EA),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesgloseTabla extends StatelessWidget {
  const _DesgloseTabla({required this.items});

  final List<AdminRankingConductor> items;

  @override
  Widget build(BuildContext context) {
    final totalViajes = items.fold<int>(0, (a, b) => a + b.viajes);
    final totalAsientos = items.fold<int>(0, (a, b) => a + b.asientos);
    final totalRecaudado = items.fold<double>(0, (a, b) => a + b.recaudado);
    final totalComision = items.fold<double>(0, (a, b) => a + b.comision);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Conductor')),
          DataColumn(label: Text('Viajes')),
          DataColumn(label: Text('Asientos')),
          DataColumn(label: Text('Recaudado')),
          DataColumn(label: Text('Comisión')),
        ],
        rows: [
          for (final r in items)
            DataRow(
              onSelectChanged: (_) {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Desglose por viaje'),
                    content: SizedBox(
                      width: 520,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('${r.nombre} · ${r.placa}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: AppSpacing.sm),
                          _TripLine(label: 'Viaje 1', amount: r.recaudado * 0.4),
                          _TripLine(label: 'Viaje 2', amount: r.recaudado * 0.33),
                          _TripLine(label: 'Viaje 3', amount: r.recaudado * 0.27),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
                    ],
                  ),
                );
              },
              cells: [
                DataCell(Text(r.nombre)),
                DataCell(Text('${r.viajes}')),
                DataCell(Text('${r.asientos}')),
                DataCell(Text('S/ ${_formatNumber(r.recaudado.round())}')),
                DataCell(Text('S/ ${_formatNumber(r.comision.round())}')),
              ],
            ),
          DataRow(
            cells: [
              const DataCell(Text('Totales', style: TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text('$totalViajes', style: const TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text('$totalAsientos', style: const TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text('S/ ${_formatNumber(totalRecaudado.round())}', style: const TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text('S/ ${_formatNumber(totalComision.round())}', style: const TextStyle(fontWeight: FontWeight.w900))),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripLine extends StatelessWidget {
  const _TripLine({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('S/ ${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F172A);
    const active = Color(0xFFF97316);
    const inactive = Color(0xFF64748B);

    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: bg,
          selectedItemColor: active,
          unselectedItemColor: inactive,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go(AppRoutes.adminHome);
                return;
              case 1:
                context.go(AppRoutes.adminConductores);
                return;
              case 2:
                context.go(AppRoutes.adminPagos);
                return;
              case 3:
                context.go(AppRoutes.adminMonitoreo);
                return;
              case 4:
              default:
                context.go(AppRoutes.adminAnalitica);
                return;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_bus_rounded), label: 'Conductores'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money_rounded), label: 'Pagos'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Monitoreo'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analítica'),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(int value) {
  final s = value.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    b.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) b.write(',');
  }
  return b.toString();
}
