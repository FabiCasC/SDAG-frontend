import 'package:flutter/material.dart';
import 'views/vista_49_auto_asignado.dart'; // Importa las vistas
import 'views/vista_50_reporte_puntualidad.dart'; // Importa las vistas
import 'features/auth/screens/login_screen.dart';  // Importa la pantalla de Login

void main() {
  runApp(const SDAGApp());
}

class SDAGApp extends StatelessWidget {
  const SDAGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define las rutas de las vistas
      routes: {
        '/login': (context) => const LoginScreen(), // Ruta para Login
        '/vista49': (context) => Vista49AutoAsignado(), // Ruta para Vista 49
        '/vista50': (context) => Vista50ReportePuntualidad(), // Ruta para Vista 50
        // Agrega más rutas si es necesario para las vistas 51-64
      },
      initialRoute: '/login',  // Inicia en la pantalla de login
      debugShowCheckedModeBanner: false,
    );
  }
}