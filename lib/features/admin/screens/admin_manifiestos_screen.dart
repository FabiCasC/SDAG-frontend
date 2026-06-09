import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';
import '../providers/admin_monitoreo_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminManifiestosScreen extends ConsumerStatefulWidget {
  const AdminManifiestosScreen({super.key});

  @override
  ConsumerState<AdminManifiestosScreen> createState() => _AdminManifiestosScreenState();
}

class _AdminManifiestosScreenState extends ConsumerState<AdminManifiestosScreen> {
  final _queryController = TextEditingController();
  DateTimeRange? _range;
  AdminManifiestoEstadoFiltro _estado = AdminManifiestoEstadoFiltro.todos;

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
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (r == null) return;
    setState(() => _range = r);
  }

  @override
  Widget build(BuildContext context) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final conductoresState = ref.watch(adminConductoresProvider);
    final viajes = [...conductoresState.viajes]..sort((a, b) => b.fecha.compareTo(a.fecha));

    final q = _queryController.text.trim().toLowerCase();
    final filtered = viajes.where((v) {
      final c = ref.read(adminConductoresProvider.notifier).getById(v.conductorId);
      final name = c?.nombreCompleto ?? '—';
      final placa = c?.placa ?? '—';
      if (_range != null) {
        if (v.fecha.isBefore(_range!.start)) return false;
        if (v.fecha.isAfter(DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59))) {
          return false;
        }
      }
      if (q.isNotEmpty) {
        final hay = '$name $placa'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      final enCurso = c != null &&
          (c.estado == MockAdminConductorEstado.enRuta || c.estado == MockAdminConductorEstado.disponible) &&
          v.fecha.isAfter(DateTime.now().subtract(const Duration(hours: 12)));
      if (_estado == AdminManifiestoEstadoFiltro.completado && enCurso) return false;
      if (_estado == AdminManifiestoEstadoFiltro.enCurso && !enCurso) return false;
      return true;
    }).toList(growable: false);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Manifiestos electrónicos'),
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
                TextField(
                  controller: _queryController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar conductor (nombre o placa)',
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
                        decoration: const InputDecoration(labelText: 'Estado'),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<AdminManifiestoEstadoFiltro>(
                            value: _estado,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: AdminManifiestoEstadoFiltro.todos,
                                child: Text('Todos'),
                              ),
                              DropdownMenuItem(
                                value: AdminManifiestoEstadoFiltro.completado,
                                child: Text('Completado'),
                              ),
                              DropdownMenuItem(
                                value: AdminManifiestoEstadoFiltro.enCurso,
                                child: Text('En curso'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _estado = v ?? AdminManifiestoEstadoFiltro.todos),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay viajes con manifiesto'))),
          ...filtered.map((v) {
            final c = ref.read(adminConductoresProvider.notifier).getById(v.conductorId);
            final name = c?.nombreCompleto ?? '—';
            final placa = c?.placa ?? '—';
            final capacidad = c?.capacidad ?? 8;
            final abordaron = (capacidad - (v.id.hashCode.abs() % (capacidad + 1))).clamp(0, capacidad);
            final enCurso = c != null &&
                (c.estado == MockAdminConductorEstado.enRuta || c.estado == MockAdminConductorEstado.disponible) &&
                v.fecha.isAfter(DateTime.now().subtract(const Duration(hours: 12)));
            final (chipBg, chipLabel) = enCurso
                ? (const Color(0xFF2563EB), 'En curso')
                : (const Color(0xFF16A34A), 'Completado');

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                        Expanded(
                          child: Text(
                            '$name · $placa',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                            overflow: TextOverflow.ellipsis,
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
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatDateTime(v.fecha)} · ${v.rutaLabel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF62748E),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pasajeros: $abordaron/$capacidad abordaron',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.push('/admin/manifiestos/${v.id}'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                      ),
                      child: const Text('Ver manifiesto'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class TripPassenger {
  const TripPassenger({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.telefono,
    required this.asiento,
    required this.abordo,
  });
  final String id;
  final String nombres;
  final String apellidos;
  final String dni;
  final String telefono;
  final int asiento;
  final bool abordo;
}

final manifestProvider = FutureProvider.family<List<TripPassenger>, String>((ref, tripId) async {
  final resp = await Supabase.instance.client
      .from('reservations')
      .select('id, seats, status, profiles(id, first_name, last_name, dni, phone)')
      .eq('trip_id', tripId)
      .neq('status', 'cancelada');

  final list = <TripPassenger>[];
  for (final r in (resp as List).cast<Map<String, dynamic>>()) {
    final seats = r['seats'] as List? ?? [];
    final p = r['profiles'] as Map<String, dynamic>?;
    if (p == null) continue;

    for (final seat in seats) {
      list.add(TripPassenger(
        id: p['id'].toString(),
        nombres: p['first_name']?.toString() ?? '',
        apellidos: p['last_name']?.toString() ?? '',
        dni: p['dni']?.toString() ?? '—',
        telefono: p['phone']?.toString() ?? '—',
        asiento: seat as int,
        abordo: r['status'] == 'abordado' || r['status'] == 'completado' || r['status'] == 'confirmada', // confirmada usually means they are on board or will be
      ));
    }
  }
  list.sort((a, b) => a.asiento.compareTo(b.asiento));
  return list;
});

class AdminManifiestoDetalleScreen extends ConsumerWidget {
  const AdminManifiestoDetalleScreen({required this.viajeId, super.key});

  final String viajeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final controller = ref.read(adminConductoresProvider.notifier);
    final viajes = ref.watch(adminConductoresProvider).viajes;
    final viaje = viajes.where((v) => v.id == viajeId).cast<MockAdminViaje?>().firstWhere(
          (v) => v != null,
          orElse: () => null,
        );

    final conductor = viaje == null ? null : controller.getById(viaje.conductorId);
    final nombre = conductor?.nombreCompleto ?? '—';
    final placa = conductor?.placa ?? '—';
    final capacidad = conductor?.capacidad ?? 8;

    final manifestAsync = ref.watch(manifestProvider(viajeId));

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Manifiesto'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF0F172A),
                  content: Text('Manifiesto compartido'),
                ),
              );
            },
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: manifestAsync.when(
        data: (pasajeros) {
          final abordaron = pasajeros.where((p) => p.abordo).length;
          return ListView(
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
                      '$nombre · $placa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      viaje == null ? 'Viaje: $viajeId' : '${_formatDateTime(viaje.fecha)} · ${viaje.rutaLabel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF62748E),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pasajeros: $abordaron/$capacidad abordaron',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (pasajeros.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay pasajeros registrados'))),
              ...pasajeros.map((p) {
                final boarded = p.abordo;
                final (chipBg, chipLabel) =
                    boarded ? (const Color(0xFF16A34A), 'Abordó') : (const Color(0xFFDC2626), 'No abordó');

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.nombres} ${p.apellidos}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'DNI: ${p.dni} · Asiento ${p.asiento}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
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
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.adminManifiestos),
                child: const Text('Volver'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar manifiesto')),
      ),
    );
  }
}

String _formatDateOnly(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
}

String _formatDateTime(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$date · ${two(h)}:${two(dt.minute)} $ampm';
}
