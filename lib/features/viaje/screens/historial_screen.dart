import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = MockData.tripHistory;

    return Column(
      children: [
        Material(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: SafeArea(
            bottom: false,
            child: AppBar(
              title: const Text('Mis viajes'),
              automaticallyImplyLeading: false,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
        ),
        Expanded(
          child: trips.isEmpty
              ? const _EmptyHistory()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final t = trips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _TripCard(
                        trip: t,
                        onTap: () => context.push('${AppRoutes.passengerTripDetail}?id=${t.id}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final MockTripHistoryItem trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = trip.status == MockTripStatus.completado;

    final (chipBg, chipFg, chipLabel, icon) = completed
        ? (AppColors.seatOkBg, AppColors.success, 'Completado', Icons.check_circle_rounded)
        : (AppColors.seatBadBg, AppColors.error, 'Cancelado', Icons.cancel_rounded);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
      child: DecoratedBox(
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: chipFg),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      trip.dateLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      chipLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: chipFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                trip.routeLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${trip.driverName} · ${trip.plate}',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'S/ ${trip.amount.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (trip.ratingStars == null)
                    Text(
                      'Sin calificar',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    )
                  else
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: i < trip.ratingStars! ? AppColors.ratingStar : AppColors.border,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no tienes viajes',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cuando completes tu primer viaje, aparecerá aquí.',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
