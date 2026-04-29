import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Sistema de Despacho',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          headline6: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),  // Reemplazamos headline1 con headline6
          bodyText1: TextStyle(fontSize: 16),
        ),
      ),
      home: CarInfoPage(),
    );
  }
}

class CarInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Información del auto asignado
    String placa = "ABC-123";
    String modelo = "Toyota Hiace 2022";
    String color = "Azul";

    return Scaffold(
      appBar: AppBar(
        title: Text('Auto Asignado'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Título de la sección
            Text(
              'Información del Auto Asignado',
              style: Theme.of(context).textTheme.headline6,  // Usamos headline6 aquí
            ),
            SizedBox(height: 30),
            // Visualización de la placa
            InfoCard(
              icon: Icons.directions_car,
              title: 'Placa:',
              value: placa,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            // Visualización del modelo
            InfoCard(
              icon: Icons.car_repair,
              title: 'Modelo:',
              value: modelo,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            // Visualización del color
            InfoCard(
              icon: Icons.palette,
              title: 'Color:',
              value: color,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Color(0xFFF8FAFC), // Fondo claro
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: color,
              size: 40,
            ),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}