import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';  // Librería para gráficos

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Gráfico de Ganancias',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GraficoGananciasPage(),
    );
  }
}

class GraficoGananciasPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráficos de Ganancias Semanales'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              'Tendencia Financiera Semanal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Gráfico de ganancias semanales
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 1000),  // Semana 1, Ganancias $1000
                        FlSpot(1, 1200),  // Semana 2, Ganancias $1200
                        FlSpot(2, 1400),  // Semana 3, Ganancias $1400
                        FlSpot(3, 1100),  // Semana 4, Ganancias $1100
                        FlSpot(4, 1600),  // Semana 5, Ganancias $1600
                      ],
                      isCurved: true,
                      colors: [Colors.blue],
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Indicadores de las ganancias semanales
            Text(
              'Ganancia Total de las 5 Semanas: \$7500',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            // Botón para descargar el reporte
            ElevatedButton(
              onPressed: () {
                // Acción para descargar el reporte (esto se podría implementar más adelante)
                print('Reporte descargado');
              },
              child: Text('Descargar Reporte'),
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