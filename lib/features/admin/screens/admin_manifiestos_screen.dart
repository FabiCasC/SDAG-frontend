import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';

final adminManifiestosProvider = FutureProvider<List<AdminManifestItem>>((ref) async {
  final manifests = await Supabase.instance.client
      .from('manifests')
      .select('*, trips(*, drivers(*, profiles(*)), routes(*))')
      .order('created_at', ascending: false);

  final items = <AdminManifestItem>[];
  for (final raw in (manifests as List).cast<Map<String, dynamic>>()) {
    final trip = raw['trips'] as Map<String, dynamic>?;
    final driver = trip?['drivers'] as Map<String, dynamic>?;
    final profile = driver?['profiles'] as Map<String, dynamic>?;
    final route = trip?['routes'] as Map<String, dynamic>?;

    final createdAt = DateTime.tryParse(raw['created_at']?.toString() ?? '') ?? DateTime.now();
    final tripId = trip?['id']?.toString() ?? '';
    final driverName = _joinNames(
      profile?['first_name']?.toString(),
      profile?['last_name']?.toString(),
    );

    items.add(
      AdminManifestItem(
        manifestId: raw['id']?.toString() ?? '',
        tripId: tripId,
        createdAt: createdAt,
        driverName: driverName.isEmpty ? 'Conductor sin nombre' : driverName,
        plate: driver?['plate']?.toString() ?? 'Sin placa',
        routeName: route?['name']?.toString() ?? 'Ruta no disponible',
        status: trip?['status']?.toString() ?? 'desconocido',
      ),
    );
  }
  return items;
});

class AdminManifestItem {
  const AdminManifestItem({
    required this.manifestId,
    required this.tripId,
    required this.createdAt,
    required this.driverName,
    required this.plate,
    required this.routeName,
    required this.status,
  });

  final String manifestId;
  final String tripId;
  final DateTime createdAt;
  final String driverName;
  final String plate;
  final String routeName;
  final String status;
}

class AdminManifiestosScreen extends ConsumerStatefulWidget {
  const AdminManifiestosScreen({super.key});

  @override
  ConsumerState<AdminManifiestosScreen> createState() => _AdminManifiestosScreenState();
}

class _AdminManifiestosScreenState extends ConsumerState<AdminManifiestosScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year && value.month == now.month && value.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);
    final manifestsAsync = ref.watch(adminManifiestosProvider);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        title: const Text('Manifiestos del día'),
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
          final query = _searchController.text.trim().toLowerCase();
          final filtered = items.where((item) {
            if (!_isToday(item.createdAt)) return false;
            if (query.isEmpty) return true;
            final haystack = '${item.driverName} ${item.plate} ${item.routeName}'.toLowerCase();
            return haystack.contains(query);
          }).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por conductor, placa o ruta',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.white,
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
              const SizedBox(height: AppSpacing.md),
              _SummaryBanner(total: filtered.length),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.p20),
                  child: Center(child: Text('No hay manifiestos registrados hoy.')),
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
    final (chipBg, chipText) = switch (item.status.toLowerCase()) {
      'completado' => (const Color(0xFF16A34A), 'Completado'),
      'cancelado' => (const Color(0xFFDC2626), 'Cancelado'),
      _ => (const Color(0xFF2563EB), item.status),
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
            item.routeName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(item.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: item.tripId.isEmpty
                ? null
                : () => context.push('/admin/manifiestos/${item.tripId}'),
            child: const Text('Ver manifiesto'),
          ),
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
  for (final raw in (resp as List).cast<Map<String, dynamic>>()) {
    final seats = raw['seats'] as List? ?? [];
    final profile = raw['profiles'] as Map<String, dynamic>?;
    if (profile == null) continue;

    for (final seat in seats) {
      list.add(
        TripPassenger(
          id: profile['id']?.toString() ?? '',
          nombres: profile['first_name']?.toString() ?? '',
          apellidos: profile['last_name']?.toString() ?? '',
          dni: profile['dni']?.toString() ?? '—',
          telefono: profile['phone']?.toString() ?? '—',
          asiento: seat as int,
          abordo: raw['status'] == 'abordado' ||
              raw['status'] == 'completado' ||
              raw['status'] == 'confirmada',
        ),
      );
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
    const pageBg = Color(0xFFF8FAFC);

    final conductoresController = ref.read(adminConductoresProvider.notifier);
    final viajes = ref.watch(adminConductoresProvider).viajes;
    final viaje = viajes.where((item) => item.id == viajeId).cast<MockAdminViaje?>().firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    final conductor = viaje == null ? null : conductoresController.getById(viaje.conductorId);
    final nombre = conductor?.nombreCompleto ?? '—';
    final placa = conductor?.placa ?? '—';
    final capacidad = conductor?.capacidad ?? 8;

    final manifestAsync = ref.watch(manifestProvider(viajeId));

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        title: const Text('Manifiesto'),
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
                      viaje == null
                          ? 'Viaje: $viajeId'
                          : '${_formatDateTime(viaje.fecha)} · ${viaje.rutaLabel}',
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
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No hay pasajeros registrados'),
                  ),
                ),
              ...pasajeros.map((pasajero) {
                final (chipBg, chipLabel) = pasajero.abordo
                    ? (const Color(0xFF16A34A), 'Abordó')
                    : (const Color(0xFFDC2626), 'No abordó');

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
                                '${pasajero.nombres} ${pasajero.apellidos}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'DNI: ${pasajero.dni} · Asiento ${pasajero.asiento}',
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
        error: (error, stackTrace) => const Center(child: Text('Error al cargar manifiesto')),
      ),
    );
  }
}

String _joinNames(String? firstName, String? lastName) {
  final parts = [firstName?.trim(), lastName?.trim()]
      .whereType<String>()
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.join(' ');
}

String _formatDateTime(DateTime dt) {
  String two(int value) => value.toString().padLeft(2, '0');
  final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$date · ${two(hour)}:${two(dt.minute)} $ampm';
}
