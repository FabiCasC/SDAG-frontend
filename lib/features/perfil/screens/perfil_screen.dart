import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../app/router/app_routes.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/maps/preferred_pickup_places_dialog.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/perfil_provider.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dniController;
  late final TextEditingController _pickupController;
  bool _pickupPromptDone = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dniController = TextEditingController();
    _pickupController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferPreferredPickup());
  }

  Future<void> _maybeOfferPreferredPickup() async {
    if (_pickupPromptDone || !mounted) return;
    for (var i = 0; i < 40 && mounted; i++) {
      final p = ref.read(perfilProvider);
      if (!p.isLoading) break;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    if (!mounted) return;
    final perfil = ref.read(perfilProvider);
    if (perfil.errorMessage != null || perfil.pickup.trim().isNotEmpty) {
      _pickupPromptDone = true;
      return;
    }
    _pickupPromptDone = true;
    final saved = await showPreferredPickupPlacesDialog(context);
    if (!mounted) return;
    if (saved != null) {
      await ref.read(perfilProvider.notifier).reload();
      await ref.read(passengerSessionProvider.notifier).refreshAccount();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dniController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  void _syncControllers(PerfilState state) {
    if (_nameController.text != state.name) _nameController.text = state.name;
    if (_emailController.text != state.email) _emailController.text = state.email;
    if (_phoneController.text != state.phone) _phoneController.text = state.phone;
    if (_dniController.text != state.dni) _dniController.text = state.dni;
    if (_pickupController.text != state.pickup) _pickupController.text = state.pickup;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(passengerSessionProvider);
    final reserva = ref.watch(reservaProvider);
    final perfil = ref.watch(perfilProvider);
    final controller = ref.read(perfilProvider.notifier);

    if (perfil.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (perfil.errorMessage != null &&
        perfil.name.isEmpty &&
        perfil.email.isEmpty &&
        perfil.phone.isEmpty &&
        perfil.dni.isEmpty &&
        perfil.pickup.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                perfil.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'Reintentar',
                onPressed: controller.reload,
              ),
            ],
          ),
        ),
      );
    }

    _syncControllers(perfil);

    final account = session.account;
    final name = perfil.name.trim().isNotEmpty
        ? perfil.name.trim()
        : (account?.name?.trim().isNotEmpty ?? false)
            ? account!.name!.trim()
            : 'Usuario';

    final secondary = (perfil.email.trim().isNotEmpty)
        ? perfil.email.trim()
        : (perfil.phone.trim().isNotEmpty)
            ? perfil.phone.trim()
            : '';

    final initials = _initials(name);
    final hasActiveReservation = reserva.reservaId != null;

    return Column(
      children: [
        Material(
          color: AppColors.primaryBlue,
          child: SafeArea(
            bottom: false,
            child: AppBar(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              title: const Text('Mi perfil'),
              automaticallyImplyLeading: false,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (secondary.isNotEmpty)
                Text(
                  secondary,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle('Datos editables'),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        onChanged: controller.setName,
                        decoration: const InputDecoration(labelText: 'Nombre completo'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _emailController,
                        onChanged: controller.setEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          errorText: perfil.emailError,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _phoneController,
                        onChanged: controller.setPhone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          errorText: perfil.phoneError,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _dniController,
                        onChanged: controller.setDni,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'DNI',
                          errorText: perfil.dniError,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle('Punto de recojo preferido'),
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  border: Border.all(color: AppColors.primaryBlue),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.gps_fixed_rounded, color: AppColors.primaryBlue),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Punto de recojo preferido',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _pickupController,
                              onChanged: controller.setPickup,
                              decoration: InputDecoration(
                                labelText: 'Punto de recojo',
                                hintText: 'Ingresa tu punto habitual',
                                errorText: perfil.pickupError,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle('Método de pago guardado'),
              const SizedBox(height: AppSpacing.md),
              if (perfil.metodoPago != null)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card_rounded, color: AppColors.primaryBlue),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            perfil.metodoPago!.label,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ok = await _confirmDeletePayment(context);
                            if (!context.mounted) return;
                            if (!ok) return;
                            await controller.removeMetodoPago();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () => _openAddPayment(context, controller),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
                  child: const Text('Agregar método de pago'),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Guardar cambios',
                loading: perfil.isSaving,
                onPressed: (!perfil.hasChanges || !perfil.isValid || perfil.isSaving)
                    ? null
                    : () async {
                        final ok = await controller.updatePerfil();
                        if (!context.mounted) return;
                        if (ok) {
                          AppSnackbars.success(context, 'Perfil actualizado correctamente');
                        } else {
                          AppSnackbars.error(
                            context,
                            ref.read(perfilProvider).errorMessage ?? 'No se pudo actualizar el perfil',
                          );
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () async {
                    final ok = await _confirmLogout(context, hasActiveReservation);
                    if (!context.mounted) return;
                    if (!ok) return;
                    ref.read(passengerSessionProvider.notifier).logout();
                    await Supabase.instance.client.auth.signOut();
                    if (!context.mounted) return;
                    context.go(AppRoutes.login);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  child: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openAddPayment(BuildContext context, PerfilController controller) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Agregar método de pago',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: 'Yape',
                onPressed: () => Navigator.of(context).pop('yape'),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'Tarjeta',
                onPressed: () => Navigator.of(context).pop('tarjeta'),
              ),
            ],
          ),
        );
      },
    );

    if (option == null) return;
    if (!context.mounted) return;

    final last4 = await _askLast4(context, option);
    if (!context.mounted) return;
    if (last4 == null) return;
    await controller.setMetodoPago(type: option, last4: last4);
  }

  Future<String?> _askLast4(BuildContext context, String type) async {
    final c = TextEditingController();
    final label = type == 'yape' ? 'Número Yape' : 'Número de tarjeta';
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.p20,
            right: AppSpacing.p20,
            top: AppSpacing.p20,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: c,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número',
                  hintText: 'Ingresa el número',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Guardar',
                onPressed: () {
                  final digits = c.text.replaceAll(RegExp(r'\D'), '');
                  final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
                  Navigator.of(context).pop(last4.isEmpty ? null : last4);
                },
              ),
            ],
          ),
        );
      },
    );
    c.dispose();
    return result;
  }

  Future<bool> _confirmDeletePayment(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar método'),
          content: const Text('¿Seguro que deseas eliminar el método de pago guardado?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _confirmLogout(BuildContext context, bool hasActiveReservation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: Text(
            hasActiveReservation
                ? 'Tienes un viaje activo. Si cierras sesión no podrás ver tu reserva. ¿Deseas continuar?'
                : '¿Seguro que quieres cerrar sesión?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                hasActiveReservation ? 'Cerrar sesión de todas formas' : 'Cerrar sesión',
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
