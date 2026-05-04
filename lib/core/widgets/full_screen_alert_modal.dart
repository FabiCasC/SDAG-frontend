import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class FullScreenAlertModal extends StatelessWidget {
  final String driverName;
  final String plate;
  final List<String> expiredDocs;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  const FullScreenAlertModal({
    super.key,
    required this.driverName,
    required this.plate,
    required this.expiredDocs,
    required this.onCancel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.energeticOrange,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: AppColors.white),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '¡ALERTA CRÍTICA!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Documentos Vencidos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildDetailRow('Conductor:', driverName, context),
              _buildDetailRow('Placa:', plate, context),
              _buildDetailRow('Vencidos:', expiredDocs.join(', '), context),
              const Spacer(),
              ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.energeticOrange,
                ),
                child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: onContinue,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.white, width: 2),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  ),
                ),
                child: const Text('CONTINUAR Y ASUMIR RIESGO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white)),
        ],
      ),
    );
  }
}
