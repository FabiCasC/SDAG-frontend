import 'package:flutter/material.dart';

void main() {
  runApp(const SDAGApp());
}

class SDAGApp extends StatelessWidget {
  const SDAGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Gestión de Cabina',
      debugShowCheckedModeBanner: false,
      // CAPA LÓGICA DE BRANDING (Lo que los 5 deben heredar)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0044FF), // Azul Trustworthy
          primary: const Color(0xFF0044FF),
          secondary: const Color(0xFFFF8800), // Naranja Energetic
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0044FF),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SDAG - Panel Principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus, size: 80, color: Color(0xFF0044FF)),
            const SizedBox(height: 20),
            Text('Bienvenido al Sistema SDAG',
                 style: Theme.of(context).textTheme.headlineSmall),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Sistema de Despacho Automatizado y Gestión de Cabina',
                          textAlign: TextAlign.center),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('INGRESAR AL SISTEMA'),
            ),
          ],
        ),
      ),
    );
  }
}