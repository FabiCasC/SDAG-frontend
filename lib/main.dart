import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

// Importa las vistas que creamos (del 49 al 64)
import 'views/vista_49_auto_asignado.dart';
import 'views/vista_50_reporte_puntualidad.dart';
// Agrega más vistas según sea necesario

void main() {
  runApp(const SDAGApp());
}

class SDAGApp extends StatelessWidget {
  const SDAGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG',
      theme: AppTheme.lightTheme,
      // Define las rutas de las vistas
      routes: {
        '/login': (context) => const LoginScreen(),  // Ruta de Login
        '/vista49': (context) => Vista49AutoAsignado(), // Ruta para Vista 49
        '/vista50': (context) => Vista50ReportePuntualidad(), // Ruta para Vista 50
        // Agrega más rutas aquí para las vistas del 51 al 64
      },
      initialRoute: '/login',  // Inicia en la pantalla de login
      debugShowCheckedModeBanner: false,
    );
  }
}