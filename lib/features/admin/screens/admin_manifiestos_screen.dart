import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

final adminManifiestosProvider = FutureProvider<List<AdminManifestItem>>((ref) async {
  final manifests = await Supabase.instance.client
      .from('manifests')
      .select('''
        id, estado, created_at,
        trips(
          id, status, scheduled_departure_at, started_at, finished_at,
          routes(name, from_label, to_label),
          drivers(id, plate, vehicle_type, capacity, profiles(name, phone))
        )
      ''')
      .order('created_at', ascending: false);

  final items = <AdminManifestItem>[];
  for (final raw in (manifests as List).cast<Map<String, dynamic>>()) {
    final manifestId = raw['id']?.toString() ?? '';
    final createdAt = DateTime.tryParse(raw['created_at']?.toString() ?? '');
    final estado = raw['estado']?.toString() ?? 'en_curso';

    final trip = raw['trips'] as Map<String, dynamic>?;
    final tripId = trip?['id']?.toString() ?? '';
    final tripStatus = trip?['status']?.toString() ?? 'desconocido';

    final route = trip?['routes'] as Map<String, dynamic>?;
    final routeName = route?['name']?.toString() ?? 'Ruta no disponible';
    final fromLabel = route?['from_label']?.toString() ?? '';
    final toLabel = route?['to_label']?.toString() ?? '';

    final driver = trip?['drivers'] as Map<String, dynamic>?;
    final driverId = driver?['id']?.toString() ?? '';
    final plate = driver?['plate']?.toString() ?? 'Sin placa';

    final profile = driver?['profiles'] as Map<String, dynamic>?;
    final driverName = profile?['name']?.toString().trim() ?? '';

    final scheduledAt = DateTime.tryParse(trip?['scheduled_departure_at']?.toString() ?? '');
    final startedAt = DateTime.tryParse(trip?['started_at']?.toString() ?? '');
    final finishedAt = DateTime.tryParse(trip?['finished_at']?.toString() ?? '');

    final displayAt = scheduledAt ?? startedAt ?? finishedAt ?? createdAt ?? DateTime.now();

    items.add(
      AdminManifestItem(
        manifestId: manifestId,
        manifestEstado: estado,
        createdAt: createdAt ?? DateTime.now(),
        displayAt: displayAt,
        tripId: tripId,
        tripStatus: tripStatus,
        driverId: driverId,
        driverName: driverName.isEmpty ? 'Conductor' : driverName,
        plate: plate,
        routeName: routeName,
        fromLabel: fromLabel,
        toLabel: toLabel,
        passengerCount: 0,
      ),
    );
  }

  final ids = items.map((e) => e.manifestId).where((id) => id.isNotEmpty).toList(growable: false);
  if (ids.isEmpty) return items;

  final entryRows = await Supabase.instance.client
      .from('manifest_entries')
      .select('manifest_id, reservation_id')
      .inFilter('manifest_id', ids);

  final counts = <String, int>{};
  for (final raw in (entryRows as List).cast<Map<String, dynamic>>()) {
    final manifestId = raw['manifest_id']?.toString();
    final reservationId = raw['reservation_id']?.toString();
    if (manifestId == null || manifestId.isEmpty) continue;
    if (reservationId == null || reservationId.isEmpty) continue;
    counts[manifestId] = (counts[manifestId] ?? 0) + 1;
  }

  return [
    for (final item in items)
      item.copyWith(passengerCount: counts[item.manifestId] ?? 0),
  ];
});

class AdminManifestItem {
  const AdminManifestItem({
    required this.manifestId,
    required this.manifestEstado,
    required this.createdAt,
    required this.displayAt,
    required this.tripId,
    required this.tripStatus,
    required this.driverId,
    required this.driverName,
    required this.plate,
    required this.routeName,
    required this.fromLabel,
    required this.toLabel,
    required this.passengerCount,
  });

  final String manifestId;
  final String manifestEstado;
  final DateTime createdAt;
  final DateTime displayAt;
  final String tripId;
  final String tripStatus;
  final String driverId;
  final String driverName;
  final String plate;
  final String routeName;
  final String fromLabel;
  final String toLabel;
  final int passengerCount;

  AdminManifestItem copyWith({int? passengerCount}) {
    return AdminManifestItem(
      manifestId: manifestId,
      manifestEstado: manifestEstado,
      createdAt: createdAt,
      displayAt: displayAt,
      tripId: tripId,
      tripStatus: tripStatus,
      driverId: driverId,
      driverName: driverName,
      plate: plate,
      routeName: routeName,
      fromLabel: fromLabel,
      toLabel: toLabel,
      passengerCount: passengerCount ?? this.passengerCount,
    );
  }
}

class AdminManifiestosScreen extends ConsumerStatefulWidget {
  const AdminManifiestosScreen({super.key});

  @override
  ConsumerState<AdminManifiestosScreen> createState() => _AdminManifiestosScreenState();
}

class _AdminManifiestosScreenState extends ConsumerState<AdminManifiestosScreen> {
  String? _selectedDriverId;
  DateTime? _selectedDate;
  String? _selectedEstado;

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);
    final manifestsAsync = ref.watch(adminManifiestosProvider);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        title: const Text('Manifiestos'),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(adminManifiestosProvider),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: manifestsAsync.when(
        data: (items) {
          final drivers = <String, String>{};
          for (final item in items) {
            if (item.driverId.isEmpty) continue;
            drivers[item.driverId] = '${item.driverName} · ${item.plate}';
          }

          final filtered = items.where((item) {
            if (_selectedDriverId != null && _selectedDriverId!.isNotEmpty) {
              if (item.driverId != _selectedDriverId) return false;
            }
            if (_selectedEstado != null && _selectedEstado!.isNotEmpty) {
              if (item.manifestEstado != _selectedEstado) return false;
            }
            if (_selectedDate != null && !_sameDay(item.displayAt, _selectedDate!)) return false;
            return true;
          }).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              _FiltersCard(
                drivers: drivers,
                selectedDriverId: _selectedDriverId,
                selectedDate: _selectedDate,
                selectedEstado: _selectedEstado,
                onDriverChanged: (value) => setState(() => _selectedDriverId = value),
                onEstadoChanged: (value) => setState(() => _selectedEstado = value),
                onDateChanged: (value) => setState(() => _selectedDate = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryBanner(total: filtered.length),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.p20),
                  child: Center(child: Text('No hay manifiestos con esos filtros.')),
                ),
              ...filtered.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ManifestCard(item: item),
                ),
              ),
            ],
          );
        },
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
                  'No se pudieron cargar los manifiestos.',
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
                  onPressed: () => ref.refresh(adminManifiestosProvider),
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

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Manifiestos generados hoy',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManifestCard extends StatelessWidget {
  const _ManifestCard({required this.item});

  final AdminManifestItem item;

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipText) = switch (item.tripStatus.toLowerCase()) {
      'completado' => (const Color(0xFF16A34A), 'Completado'),
      'cancelado' => (const Color(0xFFDC2626), 'Cancelado'),
      _ => (const Color(0xFF2563EB), item.tripStatus),
    };

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
                  '${item.driverName} · ${item.plate}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
          const SizedBox(height: 6),
          Text(
            item.fromLabel.isEmpty || item.toLabel.isEmpty ? item.routeName : '${item.fromLabel} → ${item.toLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(item.displayAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pasajeros: ${item.passengerCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  item.manifestEstado,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: item.manifestId.isEmpty
                ? null
                : () => context.push('/admin/manifiestos/${item.manifestId}'),
            child: const Text('Ver manifiesto'),
          ),
        ],
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.drivers,
    required this.selectedDriverId,
    required this.selectedDate,
    required this.selectedEstado,
    required this.onDriverChanged,
    required this.onDateChanged,
    required this.onEstadoChanged,
  });

  final Map<String, String> drivers;
  final String? selectedDriverId;
  final DateTime? selectedDate;
  final String? selectedEstado;
  final ValueChanged<String?> onDriverChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<String?> onEstadoChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          SizedBox(
            width: 280,
            child: DropdownButtonFormField<String?>(
              key: ValueKey<String?>(selectedDriverId),
              isExpanded: true,
              initialValue: selectedDriverId,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos los conductores')),
                ...drivers.entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: onDriverChanged,
              decoration: const InputDecoration(
                labelText: 'Conductor',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              key: ValueKey<String?>(selectedEstado),
              isExpanded: true,
              initialValue: selectedEstado,
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos los estados')),
                DropdownMenuItem(value: 'en_curso', child: Text('en_curso')),
                DropdownMenuItem(value: 'completado', child: Text('completado')),
                DropdownMenuItem(value: 'cancelado', child: Text('cancelado')),
              ],
              onChanged: onEstadoChanged,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: OutlinedButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                );
                if (picked == null) return;
                onDateChanged(picked);
              },
              child: Text(
                selectedDate == null ? 'Filtrar por fecha' : _formatDate(selectedDate!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (selectedDate != null)
            SizedBox(
              width: 120,
              child: OutlinedButton(
                onPressed: () => onDateChanged(null),
                child: const Text('Limpiar'),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  String two(int value) => value.toString().padLeft(2, '0');
  final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$date · ${two(hour)}:${two(dt.minute)} $ampm';
}

String _formatDate(DateTime dt) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
