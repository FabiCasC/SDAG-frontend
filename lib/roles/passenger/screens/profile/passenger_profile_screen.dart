import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/providers/passenger/controllers/connectivity_controller.dart';
import '../../../../app/providers/passenger/controllers/passenger_profile_controller.dart';
import '../../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/design/app_spacing.dart';
import '../../../../shared/maps/preferred_pickup_places_dialog.dart';
import '../../../../shared/widgets/reusable_ui_components.dart';

class PassengerProfileScreen extends ConsumerStatefulWidget {
  const PassengerProfileScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends ConsumerState<PassengerProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _pickupController;
  bool _pickupPromptScheduled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _pickupController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapProfile());
  }

  Future<void> _bootstrapProfile() async {
    final notifier = ref.read(passengerProfileControllerProvider.notifier);
    await notifier.loadFromAuthProfile();
    if (!mounted) return;
    final st = ref.read(passengerProfileControllerProvider);
    final pickup = st?.preferredPickup.trim() ?? '';
    if (_pickupPromptScheduled) return;
    if (widget.onboarding || pickup.isEmpty) {
      _pickupPromptScheduled = true;
      final saved = await showPreferredPickupPlacesDialog(context);
      if (!mounted) return;
      if (saved != null) {
        await notifier.loadFromAuthProfile();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  void _syncControllers(PassengerProfileState state) {
    if (_nameController.text != state.name) _nameController.text = state.name;
    if (_emailController.text != state.email) _emailController.text = state.email;
    if (_phoneController.text != state.phone) _phoneController.text = state.phone;
    if (_pickupController.text != state.preferredPickup) {
      _pickupController.text = state.preferredPickup;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final session = ref.watch(passengerSessionProvider);
    final account = session.account;
    final online = ref.watch(connectivityProvider);

    final profileState = ref.watch(passengerProfileControllerProvider);
    final controller = ref.read(passengerProfileControllerProvider.notifier);

    if (userId == null || profileState == null) {
      return const PlaceholderPage(
        title: 'Perfil',
        subtitle: 'No existe una cuenta asociada.',
      );
    }

    _syncControllers(profileState);

    return ListView(
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
                    onPressed: () => ref.read(connectivityProvider.notifier).state = true,
                  ),
                ],
              ),
            ),
          ),
        if (!online) const SizedBox(height: AppSpacing.md),
        if (widget.onboarding)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Completa tu perfil',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Necesitamos tus datos para continuar con tu cuenta.'),
                ],
              ),
            ),
          ),
        if (widget.onboarding) const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Datos personales',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _nameController,
                  label: 'Nombre',
                  keyboardType: TextInputType.name,
                  hint: 'Tu nombre',
                ),
                if (profileState.nameError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(profileState.nameError!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _emailController,
                  label: 'Correo',
                  keyboardType: TextInputType.emailAddress,
                  hint: 'correo@ejemplo.com',
                ),
                if (profileState.emailError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(profileState.emailError!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phoneController,
                  label: 'Teléfono',
                  keyboardType: TextInputType.phone,
                  hint: '9XXXXXXXX',
                ),
                if (profileState.phoneError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(profileState.phoneError!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Guardar cambios',
                  loading: profileState.isSaving,
                  onPressed: !online
                      ? null
                      : () async {
                          controller.setName(_nameController.text);
                          controller.setEmail(_emailController.text);
                          controller.setPhone(_phoneController.text);
                          controller.setPreferredPickup(_pickupController.text);

                          final error = await controller.save();
                          if (!context.mounted) return;
                          if (error != null) {
                            AppSnackbars.error(context, error);
                          } else {
                            AppSnackbars.success(context, 'Cambios guardados');
                          }
                        },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Punto de recojo preferido',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (profileState.preferredPickup.trim().isEmpty)
                  const Text('Sin punto de recojo guardado.')
                else
                  Text('Actual: ${profileState.preferredPickup}'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _pickupController,
                  label: 'Editar punto de recojo',
                  hint: 'Ej: Av. Javier Prado, paradero...',
                  keyboardType: TextInputType.streetAddress,
                ),
                if (profileState.pickupError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(profileState.pickupError!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Guardar',
                        loading: profileState.isSaving,
                        onPressed: !online
                            ? null
                            : () async {
                                controller.setPreferredPickup(_pickupController.text);
                                final error = await controller.save();
                                if (!context.mounted) return;
                                if (error != null) {
                                  AppSnackbars.error(context, error);
                                } else {
                                  AppSnackbars.success(context, 'Punto de recojo guardado');
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Eliminar',
                        onPressed: (profileState.preferredPickup.trim().isEmpty || !online)
                            ? null
                            : () async {
                                final error = await controller.deletePreferredPickup();
                                if (!context.mounted) return;
                                if (error != null) {
                                  AppSnackbars.error(context, error);
                                } else {
                                  _pickupController.text = '';
                                  AppSnackbars.success(context, 'Punto de recojo eliminado');
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cuenta',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppSecondaryButton(
                  label: 'Métodos de pago',
                  icon: Icons.credit_card,
                  onPressed: () => context.push(AppRoutes.passengerPaymentMethods),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSecondaryButton(
                  label: 'Cerrar sesión',
                  icon: Icons.logout,
                  onPressed: () async {
                    final confirmed = await _confirmLogout(context, account?.hasActiveReservation ?? false);
                    if (!context.mounted) return;
                    if (!confirmed) return;

                    ref.read(passengerSessionProvider.notifier).logout();
                    context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Future<bool> _confirmLogout(BuildContext context, bool hasActiveReservation) async {
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
                    'Cerrar sesión',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('¿Deseas cerrar tu sesión?'),
                  if (hasActiveReservation) ...[
                    const SizedBox(height: AppSpacing.md),
                    const AppStatusChip(
                      type: AppStatusChipType.pending,
                      label: 'Tienes una reserva activa',
                    ),
                  ],
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
                          label: 'Confirmar',
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
