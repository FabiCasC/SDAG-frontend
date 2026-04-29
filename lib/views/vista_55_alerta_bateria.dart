import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Alerta de Batería Baja',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AlertaBateriaPage(),
    );
  }
}

class AlertaBateriaPage extends StatefulWidget {
  @override
  _AlertaBateriaPageState createState() => _AlertaBateriaPageState();
}

class _AlertaBateriaPageState extends State<AlertaBateriaPage> {
  // Simulación del nivel de batería
  double _nivelBateria = 0.25; // 25% de batería (puedes cambiar este valor para simular diferentes niveles)

  void _verificarBateria() {
    // Simulación de la alerta de batería baja
    if (_nivelBateria < 0.2) {
      // Si la batería está por debajo del 20%, mostrar la alerta
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Alerta de Batería Baja'),
          content: Text('El nivel de batería es bajo. Por favor, cargue su dispositivo.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      // Si la batería está por encima del 20%, no mostrar la alerta
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('La batería está en un nivel adecuado.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerta de Batería Baja'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Título de la sección
            Text(
              'Verificar nivel de batería del conductor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            // Mostrar el nivel de batería simulado
            Text(
              'Nivel de Batería: ${(_nivelBateria * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            // Botón para verificar el nivel de batería
            ElevatedButton(
              onPressed: _verificarBateria,
              child: Text('Verificar Batería'),
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