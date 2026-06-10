import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_monitoreo_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

const _historialRouteA = 'San Isidro → Chosica';
const _historialRouteB = 'Chosica → San Isidro';

final adminHistorialViajesProvider = FutureProvider.family
    .autoDispose<List<AdminTripHistoryItem>, AdminTripHistoryRequest>((ref, request) async {
  String? driverId = request.driverId;

  if (driverId == null && request.conductorProfileId != null && request.conductorProfileId!.isNotEmpty) {
    final driverRow = await Supabase.instance.client
        .from('drivers')
        .select('id')
        .eq('profile_id', request.conductorProfileId!)
        .maybeSingle();
    driverId = driverRow?['id']?.toString();
  }

  final baseQuery = Supabase.instance.client
      .from('trips')
      .select('''
        id, driver_id, status, started_at, finished_at, amount_total,
        routes(name, from_label, to_label),
        reservations(id, passenger_profile_id, seats, amount),
        drivers(id, profile_id, plate, capacity, commission_pct, profiles(name))
      ''')
      .eq('status', 'completado')
      .gte('finished_at', request.fechaInicio.toIso8601String())
      .lte('finished_at', request.fechaFin.toIso8601String());

  final trips = await ((driverId != null && driverId.isNotEmpty)
      ? baseQuery.eq('driver_id', driverId).order('finished_at', ascending: false)
      : baseQuery.order('finished_at', ascending: false));
  final items = <AdminTripHistoryItem>[];

  for (final raw in (trips as List).cast<Map<String, dynamic>>()) {
    final driver = _asMap(raw['drivers']);
    final profile = _asMap(driver?['profiles']);
    final route = _asMap(raw['routes']);
    final routeLabel = _normalizeRouteLabel(route);

    if (request.ruta == AdminViajeRutaFiltro.sanIsidroChosica && routeLabel != _historialRouteA) {
      continue;
    }
    if (request.ruta == AdminViajeRutaFiltro.chosicaSanIsidro && routeLabel != _historialRouteB) {
      continue;
    }

    final driverName = profile?['name']?.toString().trim() ?? 'Conductor';
    final plate = driver?['plate']?.toString() ?? 'Sin placa';
    final haystack = '$driverName $plate $routeLabel'.toLowerCase();
    if (request.query.isNotEmpty && !haystack.contains(request.query.toLowerCase())) {
      continue;
    }

    final reservations = _asList(raw['reservations']).whereType<Map<String, dynamic>>().toList(growable: false);
    var pasajeros = 0;
    var montoReservas = 0.0;
    for (final reservation in reservations) {
      final seats = _asList(reservation['seats']);
      pasajeros += seats.isEmpty ? 1 : seats.length;
      montoReservas += (reservation['amount'] as num?)?.toDouble() ?? 0;
    }

    final total = (raw['amount_total'] as num?)?.toDouble() ?? montoReservas;
    final pct = (driver?['commission_pct'] as num?)?.toDouble() ?? 0;

    items.add(
      AdminTripHistoryItem(
        tripId: raw['id']?.toString() ?? '',
        driverId: driver?['id']?.toString() ?? '',
        driverProfileId: driver?['profile_id']?.toString() ?? '',
        driverName: driverName,
        plate: plate,
        capacity: (driver?['capacity'] as num?)?.toInt() ?? 0,
        routeLabel: routeLabel,
        startedAt: DateTime.tryParse(raw['started_at']?.toString() ?? ''),
        finishedAt: DateTime.tryParse(raw['finished_at']?.toString() ?? '') ?? request.fechaFin,
        passengerCount: pasajeros,
        amountTotal: total,
        commissionAmount: total * pct / 100,
      ),
    );
  }

  return items;
});

class AdminTripHistoryRequest {
  const AdminTripHistoryRequest({
    required this.conductorProfileId,
    required this.driverId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.query,
    required this.ruta,
  });

  final String? conductorProfileId;
  final String? driverId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String query;
  final AdminViajeRutaFiltro ruta;

  @override
  bool operator ==(Object other) {
    return other is AdminTripHistoryRequest &&
        other.conductorProfileId == conductorProfileId &&
        other.driverId == driverId &&
        other.fechaInicio == fechaInicio &&
        other.fechaFin == fechaFin &&
        other.query == query &&
        other.ruta == ruta;
  }

  @override
  int get hashCode => Object.hash(conductorProfileId, driverId, fechaInicio, fechaFin, query, ruta);
}

class AdminTripHistoryItem {
  const AdminTripHistoryItem({
    required this.tripId,
    required this.driverId,
    required this.driverProfileId,
    required this.driverName,
    required this.plate,
    required this.capacity,
    required this.routeLabel,
    required this.startedAt,
    required this.finishedAt,
    required this.passengerCount,
    required this.amountTotal,
    required this.commissionAmount,
  });

  final String tripId;
  final String driverId;
  final String driverProfileId;
  final String driverName;
  final String plate;
  final int capacity;
  final String routeLabel;
  final DateTime? startedAt;
  final DateTime finishedAt;
  final int passengerCount;
  final double amountTotal;
  final double commissionAmount;
}

class AdminHistorialViajesScreen extends ConsumerStatefulWidget {
  const AdminHistorialViajesScreen({this.conductorId, super.key});

  final String? conductorId;

  @override
  ConsumerState<AdminHistorialViajesScreen> createState() => _AdminHistorialViajesScreenState();
}

class _AdminHistorialViajesScreenState extends ConsumerState<AdminHistorialViajesScreen> {
  final _queryController = TextEditingController();
  late DateTimeRange _range;
  AdminViajeRutaFiltro _ruta = AdminViajeRutaFiltro.todos;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

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
      initialDateRange: _range,
    );
    if (r == null) return;
    setState(() => _range = r);
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);
    const appBarBg = Color(0xFF0F172A);

    final request = AdminTripHistoryRequest(
      conductorProfileId: widget.conductorId,
      driverId: null,
      fechaInicio: DateTime(_range.start.year, _range.start.month, _range.start.day),
      fechaFin: DateTime(_range.end.year, _range.end.month, _range.end.day, 23, 59, 59),
      query: _queryController.text.trim(),
      ruta: _ruta,
    );
    final tripsAsync = ref.watch(adminHistorialViajesProvider(request));

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Historial de viajes'),
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
                  enabled: widget.conductorId == null,
                  decoration: InputDecoration(
                    hintText: widget.conductorId == null ? 'Buscar por conductor, placa o ruta' : 'Búsqueda deshabilitada',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SizedBox(
                      width: 280,
                      child: OutlinedButton(
                        onPressed: _pickRange,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                        ),
                        child: Text(
                          '${_formatDateOnly(_range.start)} - ${_formatDateOnly(_range.end)}',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<AdminViajeRutaFiltro>(
                        initialValue: _ruta,
                        decoration: const InputDecoration(
                          labelText: 'Ruta',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: AdminViajeRutaFiltro.todos, child: Text('Todas')),
                          DropdownMenuItem(
                            value: AdminViajeRutaFiltro.sanIsidroChosica,
                            child: Text('San Isidro → Chosica'),
                          ),
                          DropdownMenuItem(
                            value: AdminViajeRutaFiltro.chosicaSanIsidro,
                            child: Text('Chosica → San Isidro'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _ruta = v ?? AdminViajeRutaFiltro.todos),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _queryController.clear();
                        final now = DateTime.now();
                        _range = DateTimeRange(
                          start: DateTime(now.year, now.month, 1),
                          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
                        );
                        _ruta = AdminViajeRutaFiltro.todos;
                      }),
                      icon: const Icon(Icons.clear_rounded),
                      label: const Text('Limpiar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          tripsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Sin viajes en este período')),
                );
              }
              return Column(
                children: [
                  for (final v in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                        onTap: () => context.push('/admin/historial-viajes/${v.tripId}'),
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
                                        _initials(v.driverName),
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
                                          '${v.driverName} · ${v.plate}',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w900,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(v.finishedAt),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: const Color(0xFF62748E),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const _TripStatusChip(),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                v.routeLabel,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Pasajeros: ${v.passengerCount}/${v.capacity}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'S/ ${v.amountTotal.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Comisión: S/ ${v.commissionAmount.toStringAsFixed(2)}',
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
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Error al cargar historial: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStatusChip extends StatelessWidget {
  const _TripStatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Completado',
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

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
    return value.first as Map<String, dynamic>;
  }
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  if (value == null) return const [];
  return [value];
}

String _normalizeRouteLabel(Map<String, dynamic>? route) {
  if (route == null) return 'Ruta no disponible';
  final from = route['from_label']?.toString().trim() ?? '';
  final to = route['to_label']?.toString().trim() ?? '';
  final name = route['name']?.toString().trim() ?? '';
  final label = (from.isNotEmpty && to.isNotEmpty) ? '$from → $to' : name;
  if (label == _historialRouteA || label == _historialRouteB) {
    return label;
  }
  return name.isNotEmpty ? name : 'Ruta no disponible';
}
