import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_simulation_service.dart';
import '../../dashboard/screens/owner_dashboard_screen.dart';
import '../../driver/screens/driver_validation_screen.dart';
import '../../passenger/screens/passenger_flow_screens.dart';
import '../../main_navigation/presentation/pages/controller_main_page.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _updatePromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowUpdate());
  }

  Future<void> _maybeShowUpdate() async {
    if (!mounted) return;
    if (_updatePromptShown) return;
    _updatePromptShown = true;

    final info = TripSimulationService.instance.checkForUpdate();
    if (!info.available) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !info.critical,
      builder: (context) {
        return AlertDialog(
          title: Text(info.critical ? 'Actualización crítica' : 'Actualización disponible'),
          content: Text(
            info.critical
                ? 'Debes actualizar para continuar.\nVersión actual: ${TripSimulationService.instance.currentAppVersion}\nNueva versión: ${info.latest}'
                : 'Hay una nueva versión disponible.\nVersión actual: ${TripSimulationService.instance.currentAppVersion}\nNueva versión: ${info.latest}',
          ),
          actions: [
            if (!info.critical)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Luego'),
              ),
            TextButton(
              onPressed: () async {
                final uri = Uri.tryParse(info.url);
                if (uri == null) {
                  Navigator.of(context).pop();
                  CustomSnackbar.show(context, message: 'Link roto. Perfil en mantenimiento.', isError: true);
                  return;
                }
                final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!context.mounted) return;
                if (!ok) {
                  CustomSnackbar.show(context, message: 'No se pudo abrir el enlace.', isError: true);
                  return;
                }
                if (!info.critical) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  void _openRecovery() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PasswordRecoveryScreen()),
    );
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (_dniController.text.isEmpty || _passwordController.text.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Usuario o clave inválida',
        isError: true,
      );
    } else {
      final dni = _dniController.text.trim();
      final blocked = TripSimulationService.instance.blockedDriverDnis.contains(dni);
      if (blocked) {
        CustomSnackbar.show(
          context,
          message: 'Cuenta suspendida. Contacta al dueño.',
          isError: true,
        );
        return;
      }
      late final Widget next;
      late final String role;
      switch (dni) {
        case '11111111':
          next = const OwnerNavShell();
          role = 'Dueño';
          break;
        case '22222222':
          next = const DriverNavShell();
          role = 'Conductor';
          break;
        case '99999': // DNI del controlador RF 91
          if (_passwordController.text != 'controlador') {
             CustomSnackbar.show(
              context,
              message: 'Usuario o clave inválida',
              isError: true,
            );
            return;
          }
          next = const ControllerMainPage();
          role = 'Controlador';
          break;
        default:
          next = const PassengerNavShell();
          role = 'Pasajero';
      }
      TripSimulationService.instance.setCurrentSession(dni: dni, role: role);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => next),
      );
    }
  }

  void _goToCreateUser() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PassengerSignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 80,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SDAG',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Sistema de Despacho Automatizado y Gestión de Cabina',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          label: 'DNI',
                          hint: 'Ingrese su DNI',
                          keyboardType: TextInputType.number,
                          controller: _dniController,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Clave',
                          hint: 'Ingrese su contraseña',
                          isObscure: true,
                          controller: _passwordController,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openRecovery,
                            child: const Text('Olvidé mi clave'),
                          ),
                        ),
                        Text(
                          'Demo: 11111111 = Dueño, 22222222 = Conductor, 99999 = Controlador',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: 'Ingresar',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _goToCreateUser,
                          child: const Text('Crear usuario'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String _channel = 'SMS';
  bool _sent = false;
  bool _verified = false;

  void _send() {
    final dni = _dniController.text.trim();
    if (dni.isEmpty) {
      CustomSnackbar.show(context, message: 'Ingresa tu DNI', isError: true);
      return;
    }
    final result = _trip.startPasswordRecovery(dni: dni, channel: _channel);
    setState(() {
      _sent = true;
      _verified = false;
    });
    CustomSnackbar.show(context, message: result.message, isSuccess: result.ok);
  }

  void _verify() {
    final dni = _dniController.text.trim();
    final code = _codeController.text.trim();
    final result = _trip.verifyRecoveryCode(dni: dni, code: code);
    if (!result.ok) {
      CustomSnackbar.show(context, message: result.message, isError: true);
      return;
    }
    setState(() {
      _verified = true;
    });
    CustomSnackbar.show(context, message: result.message, isSuccess: true);
  }

  void _setPassword() {
    final dni = _dniController.text.trim();
    final pw = _newPasswordController.text.trim();
    final result = _trip.setNewPassword(dni: dni, newPassword: pw);
    if (!result.ok) {
      CustomSnackbar.show(context, message: result.message, isError: true);
      return;
    }
    CustomSnackbar.show(context, message: result.message, isSuccess: true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar cuenta'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      label: 'DNI',
                      hint: 'Ingresa tu DNI',
                      keyboardType: TextInputType.number,
                      controller: _dniController,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _channel,
                      items: const [
                        DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                        DropdownMenuItem(value: 'Email', child: Text('Email')),
                      ],
                      onChanged: (v) => setState(() => _channel = v ?? 'SMS'),
                      decoration: const InputDecoration(
                        labelText: 'Canal de recuperación',
                        prefixIcon: Icon(Icons.verified_user_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Enviar código',
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_sent)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Verificación', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Código',
                        hint: '6 dígitos',
                        keyboardType: TextInputType.number,
                        controller: _codeController,
                        prefixIcon: const Icon(Icons.password_rounded),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Verificar código',
                        onPressed: _verify,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (_verified)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Nueva clave', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Clave',
                        hint: 'Mínimo 4 caracteres',
                        isObscure: true,
                        controller: _newPasswordController,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Guardar clave',
                        onPressed: _setPassword,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
