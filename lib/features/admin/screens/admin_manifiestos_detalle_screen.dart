import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

final adminManifestEntriesProvider =
    FutureProvider.family<List<AdminManifestEntry>, String>((ref, manifestId) async {
  final entries = await Supabase.instance.client
      .from('manifest_entries')
      .select('''
        id, seat_number, pickup_text, boarding, first_name, last_name, dni, phone,
        reservations(seats, amount, status)
      ''')
      .eq('manifest_id', manifestId)
      .order('seat_number');

  final list = <AdminManifestEntry>[];
  for (final raw in (entries as List).cast<Map<String, dynamic>>()) {
    final reservation = raw['reservations'];
    final reservationMap = reservation is Map<String, dynamic> ? reservation : null;
    final reservationStatus = reservationMap?['status']?.toString();
    if (reservationMap == null) continue;
    if (reservationStatus == 'cancelada') continue;

    list.add(
      AdminManifestEntry(
        id: raw['id']?.toString() ?? '',
        seatNumber: int.tryParse(raw['seat_number']?.toString() ?? '') ?? 0,
        pickupText: raw['pickup_text']?.toString() ?? '',
        boarding: raw['boarding']?.toString() ?? 'pendiente',
        firstName: raw['first_name']?.toString() ?? '',
        lastName: raw['last_name']?.toString() ?? '',
        dni: raw['dni']?.toString() ?? '—',
        phone: raw['phone']?.toString() ?? '—',
      ),
    );
  }

  return list;
});

class AdminManifestEntry {
  const AdminManifestEntry({
    required this.id,
    required this.seatNumber,
    required this.pickupText,
    required this.boarding,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.phone,
  });

  final String id;
  final int seatNumber;
  final String pickupText;
  final String boarding;
  final String firstName;
  final String lastName;
  final String dni;
  final String phone;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();
}

class AdminManifiestosDetalleScreen extends ConsumerWidget {
  const AdminManifiestosDetalleScreen({required this.manifestId, super.key});

  final String manifestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pageBg = Color(0xFFF8FAFC);
    final asyncEntries = ref.watch(adminManifestEntriesProvider(manifestId));

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        title: const Text('Manifiesto'),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(adminManifestEntriesProvider(manifestId)),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: asyncEntries.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.p20),
                child: Text('No hay pasajeros registrados en este viaje'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: Color(0xFF2563EB)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Pasajeros: ${entries.length}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Asiento #')),
                      DataColumn(label: Text('Nombre completo')),
                      DataColumn(label: Text('DNI')),
                      DataColumn(label: Text('Teléfono')),
                      DataColumn(label: Text('Punto de recojo')),
                      DataColumn(label: Text('Abordaje')),
                    ],
                    rows: [
                      for (final e in entries)
                        DataRow(
                          cells: [
                            DataCell(Text('${e.seatNumber}')),
                            DataCell(Text(e.fullName.isEmpty ? '—' : e.fullName)),
                            DataCell(Text(e.dni)),
                            DataCell(Text(e.phone)),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  e.pickupText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(_BoardingChip(value: e.boarding)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Text('Error al cargar manifiesto: $error'),
          ),
        ),
      ),
    );
  }
}

class _BoardingChip extends StatelessWidget {
  const _BoardingChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final normalized = value.toLowerCase();
    final (bg, fg, label) = switch (normalized) {
      'abordo' => (const Color(0xFF16A34A), AppColors.white, 'Abordó ✅'),
      'no_abordo' => (const Color(0xFFDC2626), AppColors.white, 'No abordó ❌'),
      _ => (const Color(0xFFF59E0B), const Color(0xFF111827), 'Pendiente ⏳'),
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
              color: fg,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

