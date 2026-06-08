import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../core/mock/mock_data.dart';
import '../providers/admin_monitoreo_provider.dart';
import '../providers/admin_conductores_provider.dart';

class AdminHistorialViajesScreen extends ConsumerStatefulWidget {
  const AdminHistorialViajesScreen({this.conductorId, super.key});

  final String? conductorId;

  @override
  ConsumerState<AdminHistorialViajesScreen> createState() => _AdminHistorialViajesScreenState();
}

class _AdminHistorialViajesScreenState extends ConsumerState<AdminHistorialViajesScreen> {
  final _queryController = TextEditingController();
  DateTimeRange? _range;
  AdminViajeRutaFiltro _ruta = AdminViajeRutaFiltro.todos;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 14)), end: now),
    );
    if (r == null) return;
    setState(() => _range = r);
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);
    const appBarBg = Color(0xFF0F172A);

    final controller = ref.read(adminConductoresProvider.notifier);
    final state = ref.watch(adminConductoresProvider);

    final conductorId = widget.conductorId;
    final conductor = conductorId == null ? null : controller.getById(conductorId);

    final all = conductorId == null
        ? List<MockAdminViaje>.of(state.viajes)
        : controller.viajesDeConductor(conductorId);
    all.sort((a, b) => b.fecha.compareTo(a.fecha));

    final q = _queryController.text.trim().toLowerCase();
    final filtered = all.where((v) {
      if (_range != null) {
        if (v.fecha.isBefore(_range!.start)) return false;
        final end = DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59);
        if (v.fecha.isAfter(end)) return false;
      }
      if (_ruta != AdminViajeRutaFiltro.todos) {
        final isSI = v.rutaLabel.toLowerCase().contains('san isidro');
        final isCh = v.rutaLabel.toLowerCase().contains('chosica');
        if (_ruta == AdminViajeRutaFiltro.sanIsidroChosica && !(isSI && v.rutaLabel.contains('→') && v.rutaLabel.contains('Chosica'))) {
          return false;
        }
        if (_ruta == AdminViajeRutaFiltro.chosicaSanIsidro && !(isCh && v.rutaLabel.contains('→') && v.rutaLabel.contains('San Isidro'))) {
          return false;
        }
      }
      if (q.isNotEmpty) {
        final c = controller.getById(v.conductorId);
        final name = c?.nombreCompleto ?? '';
        final placa = c?.placa ?? '';
        final hay = '$name $placa'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: Text(conductor == null ? 'Historial de viajes' : 'Historial · ${conductor.nombreCompleto}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _queryController,
                  onChanged: (_) => setState(() {}),
                  enabled: conductorId == null,
                  decoration: InputDecoration(
                    hintText: conductorId == null ? 'Buscar por conductor o placa' : 'Búsqueda deshabilitada',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
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
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickRange,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                        ),
                        child: Text(
                          _range == null
                              ? 'Rango de fechas'
                              : '${_formatDateOnly(_range!.start)} - ${_formatDateOnly(_range!.end)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Ruta'),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<AdminViajeRutaFiltro>(
                            value: _ruta,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: AdminViajeRutaFiltro.todos, child: Text('Todos')),
                              DropdownMenuItem(
                                value: AdminViajeRutaFiltro.sanIsidroChosica,
                                child: Text('San Isidro→Chosica'),
                              ),
                              DropdownMenuItem(
                                value: AdminViajeRutaFiltro.chosicaSanIsidro,
                                child: Text('Chosica→San Isidro'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _ruta = v ?? AdminViajeRutaFiltro.todos),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: () => setState(() {
                        _queryController.clear();
                        _range = null;
                        _ruta = AdminViajeRutaFiltro.todos;
                      }),
                      icon: const Icon(Icons.clear_rounded),
                      tooltip: 'Limpiar',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay viajes con esos filtros')))
          else
            ...filtered.map((v) {
              final c = controller.getById(v.conductorId);
              final name = c?.nombreCompleto ?? '—';
              final placa = c?.placa ?? '—';
              final capacity = c?.capacidad ?? 8;
              final ocupados = (capacity - (v.id.hashCode.abs() % (capacity + 1))).clamp(0, capacity);
              final routeTaken = v.id.hashCode.isEven ? 'La Priale' : 'Javier Prado';
              final duration = Duration(minutes: 30 + (v.id.hashCode.abs() % 20));
              final salida = v.fecha;
              final llegada = salida.add(duration);
              final recaudo = (ocupados * 15.0) + (v.id.hashCode.abs() % 10);
              final pct = c?.comisionPorcentaje ?? 15.0;
              final comision = recaudo * pct / 100;
              final status = _tripStatusFor(v, c);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  onTap: () => context.push('/admin/historial-viajes/${v.id}'),
                  child: Container(
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E40AF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _initials(name),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$name · $placa',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatDateTime(salida)} → ${_formatTimeOnly(llegada)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF62748E),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            _TripStatusChip(status: status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${v.rutaLabel} · $routeTaken',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Asientos: $ocupados/$capacity',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              'S/ ${recaudo.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Comisión: S/ ${comision.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFFF97316),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

enum _TripUiStatus { completado, enCurso, incompleto }

_TripUiStatus _tripStatusFor(MockAdminViaje v, MockAdminConductor? c) {
  if (v.estado == MockAdminViajeEstado.cancelado) return _TripUiStatus.incompleto;
  if (c == null) return _TripUiStatus.completado;
  final enCurso = c.estado == MockAdminConductorEstado.enRuta &&
      v.fecha.isAfter(DateTime.now().subtract(const Duration(hours: 6)));
  return enCurso ? _TripUiStatus.enCurso : _TripUiStatus.completado;
}

class _TripStatusChip extends StatelessWidget {
  const _TripStatusChip({required this.status});

  final _TripUiStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, label) = switch (status) {
      _TripUiStatus.completado => (const Color(0xFF16A34A), 'Completado'),
      _TripUiStatus.enCurso => (const Color(0xFF2563EB), 'En curso'),
      _TripUiStatus.incompleto => (const Color(0xFFDC2626), 'Incompleto'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

String _formatDateOnly(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
}

String _formatTimeOnly(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${two(h)}:${two(dt.minute)} $ampm';
}

String _formatDateTime(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$date · ${two(h)}:${two(dt.minute)} $ampm';
}

String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  String first(String s) => s.characters.first.toUpperCase();
  if (parts.isEmpty) return '—';
  if (parts.length == 1) return first(parts[0]);
  return '${first(parts[0])}${first(parts[1])}';
}
