import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/viaje_provider.dart';

class CalificacionScreen extends ConsumerStatefulWidget {
  const CalificacionScreen({super.key});

  @override
  ConsumerState<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends ConsumerState<CalificacionScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripId = GoRouterState.of(context).uri.queryParameters['tripId'];
    final historyTrip = tripId == null
        ? null
        : MockData.tripHistory.where((t) => t.id == tripId).cast<MockTripHistoryItem?>().firstOrNull;

    final reserva = ref.watch(reservaProvider);
    final driverName = historyTrip?.driverName ?? reserva.conductorSeleccionado?.name;

    if (driverName == null) {
      return const AppScaffold(
        title: 'Calificación',
        body: PlaceholderPage(
          title: 'Sin conductor',
          subtitle: 'No hay información del conductor para calificar.',
        ),
      );
    }

    final initials = _initials(driverName);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Calificación')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: CircleAvatar(
                radius: 54,
                backgroundColor: AppColors.primaryTint12,
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '¿Cómo fue tu viaje con $driverName?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    onPressed: () => setState(() => _rating = i + 1),
                    iconSize: 48,
                    icon: Icon(
                      Icons.star_rounded,
                      color: filled ? AppColors.energeticOrange : AppColors.border,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Enviar calificación',
              onPressed: _rating == 0
                  ? null
                  : () {
                      AppSnackbars.success(context, '¡Gracias! Tu calificación fue enviada');
                      if (historyTrip == null) {
                        ref.read(reservaProvider.notifier).reset();
                        ref.invalidate(viajeProvider);
                      }
                      context.go(AppRoutes.passengerHome);
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
                if (historyTrip == null) {
                  ref.read(reservaProvider.notifier).reset();
                  ref.invalidate(viajeProvider);
                }
                context.go(AppRoutes.passengerHome);
              },
              child: const Text('Omitir'),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
