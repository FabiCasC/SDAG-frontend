import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/passenger/controllers/connectivity_controller.dart';
import '../../../../app/providers/passenger/controllers/passenger_payment_methods_controller.dart';
import '../../../../app/providers/passenger/models/payment_method.dart';
import '../../../../shared/design/app_spacing.dart';
import '../../../../shared/widgets/reusable_ui_components.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider);
    final state = ref.watch(passengerPaymentMethodsControllerProvider);
    final controller = ref.read(passengerPaymentMethodsControllerProvider.notifier);

    return AppScaffold(
      title: 'Métodos de pago',
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!online)
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Sin conexión',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          AppSecondaryButton(
                            label: 'Reintentar',
                            onPressed: () =>
                                ref.read(connectivityProvider.notifier).state =
                                    true,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!online) const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: state.method == null
                      ? _EmptyPaymentState(
                          disabled: !online || state.isSaving,
                          onAdd: () => _openAddEditSheet(
                            context: context,
                            ref: ref,
                            existing: null,
                          ),
                        )
                      : _PaymentMethodCard(
                          method: state.method!,
                          disabled: !online || state.isSaving,
                          onToggleSave: (value) async {
                            final error = await controller.toggleSaveForFuture(value);
                            if (!context.mounted) return;
                            if (error != null) {
                              AppSnackbars.error(context, error);
                            } else {
                              AppSnackbars.success(context, 'Actualizado');
                            }
                          },
                          onEdit: () => _openAddEditSheet(
                            context: context,
                            ref: ref,
                            existing: state.method,
                          ),
                          onDelete: () async {
                            final confirm = await _confirmDelete(context);
                            if (!context.mounted) return;
                            if (!confirm) return;
                            final error = await controller.delete();
                            if (!context.mounted) return;
                            if (error != null) {
                              AppSnackbars.error(context, error);
                            } else {
                              AppSnackbars.success(context, 'Eliminado');
                            }
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _openAddEditSheet({
    required BuildContext context,
    required WidgetRef ref,
    required PaymentMethod? existing,
  }) async {
    final controller = ref.read(passengerPaymentMethodsControllerProvider.notifier);
    final online = ref.read(connectivityProvider);
    if (!online) {
      AppSnackbars.warning(context, 'Sin conexión');
      return;
    }

    final result = await showModalBottomSheet<_PaymentMethodDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _PaymentMethodSheet(existing: existing);
      },
    );

    if (result == null) return;

    final error = await controller.addMethod(
      brand: result.brand,
      last4: result.last4,
      saveForFuture: result.saveForFuture,
    );
    if (!context.mounted) return;
    if (error != null) {
      AppSnackbars.error(context, error);
    } else {
      AppSnackbars.success(context, 'Método guardado');
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Eliminar método',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('¿Deseas eliminar este método de pago?'),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Cancelar',
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Eliminar',
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}

class _EmptyPaymentState extends StatelessWidget {
  const _EmptyPaymentState({required this.disabled, required this.onAdd});

  final bool disabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sin método de pago',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Agrega un método para futuras compras.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Agregar método',
                  onPressed: disabled ? null : onAdd,
                  icon: Icons.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.disabled,
    required this.onToggleSave,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentMethod method;
  final bool disabled;
  final ValueChanged<bool> onToggleSave;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxWideContentWidth),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                method.maskedLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Guardar para futuras compras'),
                value: method.saveForFuture,
                onChanged: disabled ? null : onToggleSave,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Editar',
                      icon: Icons.edit,
                      onPressed: disabled ? null : onEdit,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Eliminar',
                      icon: Icons.delete,
                      onPressed: disabled ? null : onDelete,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const AppStatusChip(
                type: AppStatusChipType.available,
                label: 'Solo 1 método guardado',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodDraft {
  const _PaymentMethodDraft({
    required this.brand,
    required this.last4,
    required this.saveForFuture,
  });

  final PaymentBrand brand;
  final String last4;
  final bool saveForFuture;
}

class _PaymentMethodSheet extends StatefulWidget {
  const _PaymentMethodSheet({required this.existing});

  final PaymentMethod? existing;

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  late PaymentBrand _brand;
  late bool _saveForFuture;

  @override
  void initState() {
    super.initState();
    _brand = widget.existing?.brand ?? PaymentBrand.visa;
    _saveForFuture = widget.existing?.saveForFuture ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: padding,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Agregar método' : 'Editar método',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              RadioGroup<PaymentBrand>(
                groupValue: _brand,
                onChanged: (v) => setState(() => _brand = v ?? _brand),
                child: const Column(
                  children: [
                    RadioListTile<PaymentBrand>(
                      value: PaymentBrand.visa,
                      title: Text('Visa **** 4582'),
                    ),
                    RadioListTile<PaymentBrand>(
                      value: PaymentBrand.mastercard,
                      title: Text('Mastercard **** 8912'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Guardar para futuras compras'),
                value: _saveForFuture,
                onChanged: (v) => setState(() => _saveForFuture = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Guardar',
                onPressed: () {
                  final last4 = _brand == PaymentBrand.visa ? '4582' : '8912';
                  Navigator.of(context).pop(
                    _PaymentMethodDraft(
                      brand: _brand,
                      last4: last4,
                      saveForFuture: _saveForFuture,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
