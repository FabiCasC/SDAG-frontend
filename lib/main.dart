import 'package:flutter/material.dart';
import 'views/vista_49_auto_asignado.dart';  // Importar Vista 49
import 'views/vista_50_reporte_puntualidad.dart';  // Importar Vista 50
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(SDAGApp());
}

class SDAGApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Sistema de Despacho',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',  // Ruta de inicio
      routes: {
        '/login': (context) => LoginScreen(),  // Ruta para Login
        '/vista49': (context) => Vista49AutoAsignado(), // Ruta para Vista 49
        '/vista50': (context) => Vista50ReportePuntualidad(), // Ruta para Vista 50
        // Agrega más vistas si es necesario
      },
      debugShowCheckedModeBanner: false,
    );
  }
}