import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class ViajeDetalleScreen extends StatelessWidget {
  const ViajeDetalleScreen({required this.tripId, super.key});

  final String? tripId;

  @override
  Widget build(BuildContext context) {
    final trip = MockData.tripHistory.where((t) => t.id == tripId).cast<MockTripHistoryItem?>().firstOrNull;
    if (trip == null) {
      return const AppScaffold(
        title: 'Detalle del viaje',
        body: PlaceholderPage(
          title: 'Viaje no encontrado',
          subtitle: 'Vuelve al historial para seleccionar otro viaje.',
        ),
      );
    }

    return AppScaffold(
      title: trip.dateLabel,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          Text(
            'Detalle del viaje',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(label: 'Conductor', value: '${trip.driverName} · ${trip.plate}'),
                  const SizedBox(height: AppSpacing.sm),
                  _Line(label: 'Ruta', value: trip.routeLabel),
                  const SizedBox(height: AppSpacing.sm),
                  _Line(label: 'Recojo', value: trip.pickupPoint),
                  const SizedBox(height: AppSpacing.sm),
                  _Line(label: 'Asientos', value: trip.seats.map((s) => '#$s').join(', ')),
                  const SizedBox(height: AppSpacing.sm),
                  _Line(label: 'Monto', value: 'S/ ${trip.amount.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recibo digital',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DashedBorderCard(
            borderColor: AppColors.primaryBlue,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(label: 'N° Recibo', value: trip.receiptNumber),
                  const SizedBox(height: AppSpacing.sm),
                  _Line(label: 'Método', value: trip.paymentMethodLabel),
                  const SizedBox(height: AppSpacing.sm),
                  _Line(label: 'Total', value: 'S/ ${trip.amount.toStringAsFixed(0)}'),
                  const SizedBox(height: AppSpacing.md),
                  AppSecondaryButton(
                    label: 'Descargar recibo',
                    onPressed: () {
                      AppSnackbars.success(context, 'Recibo guardado en tu dispositivo');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Chat del viaje',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (trip.chatMessages.isEmpty)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'No hubo mensajes en este viaje',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Último mensaje',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      trip.lastChatMessage ?? trip.chatMessages.last.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'Ver conversación',
                      onPressed: () => context.push('${AppRoutes.passengerChat}?readonly=1&tripId=${trip.id}'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tu calificación',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (trip.ratingStars != null)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 22,
                        color: i < trip.ratingStars! ? AppColors.ratingStar : AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AppPrimaryButton(
              label: 'Calificar ahora',
              onPressed: () => context.push('${AppRoutes.passengerCalificacion}?tripId=${trip.id}'),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppSecondaryButton(
            label: 'Ver QR',
            onPressed: () => context.push('${AppRoutes.passengerQr}?tripId=${trip.id}'),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderCard extends StatelessWidget {
  const _DashedBorderCard({
    required this.borderColor,
    required this.child,
  });

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: borderColor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(AppRadius.r16),
    );

    const dash = 6.0;
    const gap = 4.0;

    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

