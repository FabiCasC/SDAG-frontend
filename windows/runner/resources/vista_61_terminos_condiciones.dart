import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Términos y Condiciones',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TerminosCondicionesPage(),
    );
  }
}

class TerminosCondicionesPage extends StatefulWidget {
  @override
  _TerminosCondicionesPageState createState() => _TerminosCondicionesPageState();
}

class _TerminosCondicionesPageState extends State<TerminosCondicionesPage> {
  bool _isAccepted = false;

  // Función para manejar la aceptación de los términos y condiciones
  void _handleAcceptance() {
    if (_isAccepted) {
      // Aquí puede ir la lógica para guardar la aceptación del usuario
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gracias por aceptar los términos y condiciones.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Por favor, acepta los términos y condiciones para continuar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Términos y Condiciones'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              'Términos y Condiciones Actualizados',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Texto simulado de los términos y condiciones
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''Términos y Condiciones de Uso:

1. Introducción.
2. Aceptación de los términos.
3. Uso del servicio.
4. Restricciones de uso.
5. Política de privacidad.
6. Responsabilidad del usuario.
7. Modificaciones a los términos.

(Estos términos son un ejemplo. En un sistema real, los términos deben ser más completos y específicos)''',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Checkbox para aceptar los términos
            Row(
              children: <Widget>[
                Checkbox(
                  value: _isAccepted,
                  onChanged: (bool? value) {
                    setState(() {
                      _isAccepted = value!;
                    });
                  },
                ),
                Text(
                  'Acepto los términos y condiciones',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Botón para confirmar la aceptación
            ElevatedButton(
              onPressed: _handleAcceptance,
              child: Text('Confirmar Aceptación'),
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