import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/conductor_reservas_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/design/app_radius.dart';

class ConductorReservasScreen extends ConsumerWidget {
  const ConductorReservasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conductorReservasProvider);

    ref.listen<ConductorReservasState>(conductorReservasProvider, (previous, next) {
      if (next.showNewReservationAlert && (previous?.showNewReservationAlert != true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white),
                SizedBox(width: 12),
                Text('¡Nueva reserva asignada!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.primaryBlue,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(conductorReservasProvider.notifier).clearAlert();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mis Reservas'),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ConductorReservasState state) {
    if (state.loading && state.reservations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null && state.reservations.isEmpty) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }
    
    if (state.reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: AppSpacing.md),
            const Text('No tienes reservas asignadas aún.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(conductorReservasProvider.notifier).loadReservations();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.reservations.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final res = state.reservations[index];
          return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  elevation: 2,
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                res.passengerName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: res.status == 'activa' ? Colors.green.shade100 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(AppRadius.r8),
                              ),
                              child: Text(
                                res.status.toUpperCase(),
                                style: TextStyle(
                                  color: res.status == 'activa' ? Colors.green.shade800 : Colors.grey.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(Icons.my_location, size: 16, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Recojo: ${res.origin}', style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.energeticOrange),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Destino: ${res.destination}', style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Fecha: ${_formatDate(res.date)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if (res.companions.isNotEmpty) ...[
                          const Divider(height: 24),
                          Text('Acompañantes (${res.companions.length}):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          ...res.companions.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(c.fullName, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          )),
                        ]
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}
