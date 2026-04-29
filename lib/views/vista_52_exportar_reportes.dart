import 'package:flutter/material.dart';

class ExportarReportesPage extends StatelessWidget {
  // Simulación de datos para el reporte
  final List<Map<String, String>> data = [
    {"Nombre": "Juan Pérez", "Puntualidad": "A tiempo", "Viajes": "20"},
    {"Nombre": "Ana Gómez", "Puntualidad": "Retrasado", "Viajes": "15"},
    {"Nombre": "Luis Martínez", "Puntualidad": "A tiempo", "Viajes": "25"},
  ];

  // Función para exportar a PDF (simplificado)
  Future<void> _exportarPDF(BuildContext context) async {
    // Simulación de generación de PDF
    await Future.delayed(Duration(seconds: 2));

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF generado exitosamente")));
  }

  // Función para exportar a Excel (simplificado)
  Future<void> _exportarExcel(BuildContext context) async {
    // Simulación de generación de Excel
    await Future.delayed(Duration(seconds: 2));

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Excel generado exitosamente")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exportar Reportes'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Título de la sección
            Text(
              'Genera y exporta los reportes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            // Botón para exportar a PDF
            ElevatedButton(
              onPressed: () => _exportarPDF(context),
              child: Text('Exportar a PDF'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 20),
            // Botón para exportar a Excel
            ElevatedButton(
              onPressed: () => _exportarExcel(context),
              child: Text('Exportar a Excel'),
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

void main() {
  runApp(MaterialApp(
    title: 'Sistema de Reportes',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: ExportarReportesPage(),
  ));
}