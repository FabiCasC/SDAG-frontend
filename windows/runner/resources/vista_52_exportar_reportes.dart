import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class ExportarReportesPage extends StatelessWidget {
  // Simulación de datos para el reporte
  final List<Map<String, String>> data = [
    {"Nombre": "Juan Pérez", "Puntualidad": "A tiempo", "Viajes": "20"},
    {"Nombre": "Ana Gómez", "Puntualidad": "Retrasado", "Viajes": "15"},
    {"Nombre": "Luis Martínez", "Puntualidad": "A tiempo", "Viajes": "25"},
  ];

  // Función para exportar a PDF
  Future<void> _exportarPDF(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Table.fromTextArray(
          data: [
            ["Nombre", "Puntualidad", "Viajes"],
            ...data.map((row) => [row["Nombre"], row["Puntualidad"], row["Viajes"]])
          ],
        );
      },
    ));

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/reporte.pdf");
    await file.writeAsBytes(await pdf.save());

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF generado en: ${file.path}")));
  }

  // Función para exportar a Excel
  Future<void> _exportarExcel(BuildContext context) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Agregar encabezados
    sheet.appendRow(["Nombre", "Puntualidad", "Viajes"]);

    // Agregar datos
    data.forEach((row) {
      sheet.appendRow([row["Nombre"], row["Puntualidad"], row["Viajes"]]);
    });

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/reporte.xlsx");
    await file.writeAsBytes(await excel.encode());

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Excel generado en: ${file.path}")));
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