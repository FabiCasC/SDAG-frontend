import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/screens/owner_dashboard_screen.dart';
import '../../driver/screens/driver_validation_screen.dart';
import '../../passenger/screens/passenger_flow_screens.dart';
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
      late final Widget next;
      switch (dni) {
        case '11111111':
          next = const OwnerDashboardScreen();
          break;
        case '22222222':
          next = const DriverValidationScreen();
          break;
        default:
          next = const PassengerRouteSearchScreen();
      }

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
                        Text(
                          'Demo: 11111111 = Dueño, 22222222 = Conductor, otro = Pasajero',
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
