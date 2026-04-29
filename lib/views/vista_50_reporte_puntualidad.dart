import 'package:flutter/material.dart';

class Vista50ReportePuntualidad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte de Puntualidad Mensual'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'Cumplimiento de Tiempos del Conductor - Abril 2026',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            MetricCard(
              title: 'Viajes a Tiempo',
              value: '120',
              color: Colors.green,
            ),
            SizedBox(height: 20),
            MetricCard(
              title: 'Viajes Retrasados',
              value: '30',
              color: Colors.red,
            ),
            SizedBox(height: 20),
            MetricCard(
              title: 'Promedio de Retraso (min)',
              value: '15',
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.blue[50],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Gráfico de Puntualidad',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        color: Colors.green,
                      ),
                      Container(
                        height: 30,
                        width: 50,
                        color: Colors.red,
                      ),
                      Container(
                        height: 70,
                        width: 50,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  MetricCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.analytics,
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