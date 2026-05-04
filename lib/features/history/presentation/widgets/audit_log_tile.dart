import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AuditLogTile extends StatelessWidget {
  final String plate;
  final DateTime date;
  final bool isBypass;
  final List<String> expiredDocs;

  const AuditLogTile({
    super.key,
    required this.plate,
    required this.date,
    this.isBypass = false,
    this.expiredDocs = const [],
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car_outlined, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      plate,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (isBypass) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.energeticOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.energeticOrange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.energeticOrange, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habilitación con documentos vencidos',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.energeticOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (expiredDocs.isNotEmpty)
                            Text(
                              'Vencidos: ${expiredDocs.join(", ")}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.energeticOrange,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
            if (!isBypass) ...[
              const SizedBox(height: AppSpacing.sm),
               Row(
                 children: [
                   const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                   const SizedBox(width: AppSpacing.sm),
                   Text(
                     'Habilitación estándar',
                     style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success),
                   ),
                 ],
               ),
            ],
          ],
        ),
      ),
    );
  }
}
