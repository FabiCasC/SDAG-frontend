import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Variable para controlar si el modo nocturno está activado
  bool _isNightMode = false;

  // Función para alternar entre modo nocturno y diurno
  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Modo Nocturno',
      theme: _isNightMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        accentColor: Colors.deepOrange,
        buttonTheme: ButtonThemeData(buttonColor: Colors.deepOrange),
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        accentColor: Colors.blueAccent,
        buttonTheme: ButtonThemeData(buttonColor: Colors.blue),
      ),
      home: ModoNocturnoPage(
        isNightMode: _isNightMode,
        toggleNightMode: _toggleNightMode,
      ),
    );
  }
}

class ModoNocturnoPage extends StatelessWidget {
  final bool isNightMode;
  final Function toggleNightMode;

  ModoNocturnoPage({required this.isNightMode, required this.toggleNightMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interfaz de Conducción'),
        actions: [
          // Switch para activar el modo nocturno
          Switch(
            value: isNightMode,
            onChanged: (value) {
              toggleNightMode();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              isNightMode ? 'Modo Nocturno Activado' : 'Modo Diurno Activado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            // Descripción de la interfaz
            Text(
              'El sistema adapta los colores de la interfaz para evitar fatiga visual del conductor.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // Simulación de la interfaz del conductor (con colores oscuros o claros)
            Container(
              color: isNightMode ? Colors.black54 : Colors.white,
              width: double.infinity,
              height: 200,
              child: Center(
                child: Text(
                  'Interfaz de Conducción',
                  style: TextStyle(
                    fontSize: 24,
                    color: isNightMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Simulación de una acción para demostrar el cambio de modo
            ElevatedButton(
              onPressed: () {
                // Acción que simula algo importante en la interfaz de conducción
                print('Acción realizada en el modo: ${isNightMode ? 'Nocturno' : 'Diurno'}');
              },
              child: Text('Simular Acción'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}