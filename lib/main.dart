import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const SDAGApp());
}

class SDAGApp extends StatelessWidget {
  const SDAGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG',  // Título de la app
      theme: AppTheme.lightTheme,  // Tema claro definido en AppTheme
      home: const LoginScreen(),  // Pantalla inicial (LoginScreen)
      debugShowCheckedModeBanner: false,  // Desactiva el banner de depuración
    );
  }
}