import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class PuntoAlternativoSheet extends StatelessWidget {
  const PuntoAlternativoSheet({
    required this.puntoAlternativo,
    super.key,
  });

  final String puntoAlternativo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.p20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'El conductor sugiere otro punto de recojo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.primaryBlue),
            ),
            child: Text(
              puntoAlternativo,
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Ver en el chat',
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.passengerChat);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: 'Entendido',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

