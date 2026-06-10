import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../providers/passenger/controllers/passenger_register_controller.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _dniController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _dniController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _birthDateController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    final controller = ref.read(passengerRegisterControllerProvider.notifier);
    final error = await controller.submit();
    if (!mounted) return;
    if (error != null) {
      AppSnackbars.error(context, error);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.go('${AppRoutes.passengerProfile}?onboarding=1');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerRegisterControllerProvider);
    final controller = ref.read(passengerRegisterControllerProvider.notifier);

    if (state.birthDate != null) {
      final formatted = _formatDate(state.birthDate!);
      if (_birthDateController.text != formatted) {
        _birthDateController.text = formatted;
      }
    }

    return AppScaffold(
      title: 'Registro',
      showAppBar: false,
      body: AppAuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBrandHeader(showSlogan: false),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              label: 'Correo',
              hint: 'correo@ejemplo.com',
              onChanged: controller.setEmail,
            ),
            if (state.emailError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.emailError!),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              label: 'DNI',
              hint: '8 dígitos',
              onChanged: controller.setDni,
            ),
            if (state.dniError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.dniError!),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _firstNameController,
              keyboardType: TextInputType.name,
              label: 'Nombre',
              hint: 'Tu nombre',
              onChanged: controller.setFirstName,
            ),
            if (state.firstNameError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.firstNameError!),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _lastNameController,
              keyboardType: TextInputType.name,
              label: 'Apellidos',
              hint: 'Tus apellidos',
              onChanged: controller.setLastName,
            ),
            if (state.lastNameError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.lastNameError!),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _birthDateController,
              readOnly: true,
              label: 'Fecha de nacimiento',
              hint: 'Seleccionar fecha',
              suffixIcon: const Icon(Icons.calendar_month),
              onTap: state.isSubmitting
                  ? null
                  : () async {
                      final now = DateTime.now();
                      final initial = state.birthDate ?? DateTime(now.year - 18, now.month, now.day);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(1900, 1, 1),
                        lastDate: now,
                      );
                      if (picked == null) return;
                      controller.setBirthDate(picked);
                      _birthDateController.text = _formatDate(picked);
                    },
            ),
            if (state.birthDateError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.birthDateError!),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              label: 'Teléfono (Perú)',
              hint: '9XXXXXXXX',
              onChanged: controller.setPhone,
            ),
            if (state.phoneError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.phoneError!),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              obscureText: true,
              label: 'Contraseña',
              hint: 'Mínimo 8 caracteres',
              onChanged: controller.setPassword,
            ),
            if (state.passwordError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppFormErrorText(state.passwordError!),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Crear cuenta',
              loading: state.isSubmitting,
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      controller.setEmail(_emailController.text);
                      controller.setDni(_dniController.text);
                      controller.setFirstName(_firstNameController.text);
                      controller.setLastName(_lastNameController.text);
                      controller.setPhone(_phoneController.text);
                      controller.setPassword(_passwordController.text);
                      await _onRegister();
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: state.isSubmitting ? null : () => context.pop(),
              child: const Text('Volver a login'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}
