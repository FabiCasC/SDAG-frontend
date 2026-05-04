import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class DriverCardItem extends StatelessWidget {
  final String name;
  final String plate;
  final bool isOnline;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  const DriverCardItem({
    super.key,
    required this.name,
    required this.plate,
    required this.isOnline,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.backgroundLight,
              child: Icon(Icons.person_outline, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Placa: $plate', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(isOnline ? 'En línea' : 'Desconectado', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            if (isOnline)
              ElevatedButton(
                onPressed: onDeactivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceGrey,
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(100, 40),
                ),
                child: const Text('Desactivar'),
              )
            else
              ElevatedButton(
                onPressed: onActivate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 40),
                ),
                child: const Text('Activar'),
              ),
          ],
        ),
      ),
    );
  }
}
