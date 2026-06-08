import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

class ReembolsoScreen extends ConsumerStatefulWidget {
  const ReembolsoScreen({required this.amount, super.key});

  final double amount;

  @override
  ConsumerState<ReembolsoScreen> createState() => _ReembolsoScreenState();
}

class _ReembolsoScreenState extends ConsumerState<ReembolsoScreen> {
  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_step >= 3) return;
      setState(() => _step += 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = _step >= 3;

    final steps = const <String>[
      'Solicitud recibida',
      'Validando pago',
      'Procesando reembolso',
      'Reembolso completado',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Reembolso'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go(AppRoutes.passengerHome),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Monto a reembolsar',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'S/ ${widget.amount.toStringAsFixed(0)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del reembolso',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(steps.length, (i) {
                      final done = _step >= i;
                      final color = done ? AppColors.success : AppColors.textSecondary;
                      final icon = done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(icon, color: color),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                steps[i],
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: done ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (!completed) ...[
                      const SizedBox(height: AppSpacing.md),
                      const LinearProgressIndicator(
                        minHeight: 6,
                        color: AppColors.primaryBlue,
                        backgroundColor: AppColors.fieldFill,
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: completed ? 'Volver al inicio' : 'Volver al inicio',
                onPressed: completed
                    ? () {
                        ref.read(reservaProvider.notifier).reset();
                        context.go(AppRoutes.passengerHome);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

