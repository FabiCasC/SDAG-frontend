import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/screens/login_screen.dart';
import 'driver_flow_screens.dart';
import '../../../shared/widgets/custom_button.dart';

class DriverValidationScreen extends StatefulWidget {
  const DriverValidationScreen({Key? key}) : super(key: key);

  @override
  State<DriverValidationScreen> createState() => _DriverValidationScreenState();
}

class _DriverValidationScreenState extends State<DriverValidationScreen> {
  bool _isBlocked = false;

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DriverMonitorCargaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlocked) {
      return _buildBlockedScreen();
    }
    return _buildAlertScreen();
  }

  Widget _buildBlockedScreen() {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        title: const Text('Pre-check normativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar a modo Alerta',
            onPressed: () {
              setState(() {
                _isBlocked = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Salir',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 80,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Acceso Bloqueado',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'SOAT o Revisión Técnica vencidos.\nContacte al Dueño.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-check normativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar a modo Bloqueado',
            onPressed: () {
              setState(() {
                _isBlocked = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Salir',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: AppColors.energeticOrange,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aviso: Su SOAT vence hoy. Regularice su situación.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Documentos válidos. Puedes iniciar la operación.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'Continuar',
                    onPressed: _continue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
