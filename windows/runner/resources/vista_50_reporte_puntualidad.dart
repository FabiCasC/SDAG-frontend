import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';  // Librería para gráficos

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Reporte de Puntualidad',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReportePuntualidadPage(),
    );
  }
}

class ReportePuntualidadPage extends StatelessWidget {
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
            // Título de la sección
            Text(
              'Cumplimiento de Tiempos del Conductor - Abril 2026',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Mostrar gráfico de barras
            Container(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(y: 30, colors: [Colors.blue]),
                      ],
                      showingTooltipIndicators: [0],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(y: 10, colors: [Colors.red]),
                      ],
                      showingTooltipIndicators: [1],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(y: 40, colors: [Colors.green]),
                      ],
                      showingTooltipIndicators: [2],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Estadísticas o métricas
            MetricCard(
              title: 'Viajes a Tiempo',
              value: '120',
              color: Colors.green,
            ),
            MetricCard(
              title: 'Viajes Retrasados',
              value: '30',
              color: Colors.red,
            ),
            MetricCard(
              title: 'Promedio de Retraso (min)',
              value: '15',
              color: Colors.blue,
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