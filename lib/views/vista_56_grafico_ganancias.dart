import 'package:flutter/material.dart';

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
            // Gráfico de ganancias semanales simulado
            Container(
              height: 300,
              color: Colors.blue[50],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Gráfico simulado con barras representando las ganancias
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        height: 50,
                        width: 30,
                        color: Colors.blue,
                      ),
                      Container(
                        height: 60,
                        width: 30,
                        color: Colors.blue,
                      ),
                      Container(
                        height: 70,
                        width: 30,
                        color: Colors.blue,
                      ),
                      Container(
                        height: 55,
                        width: 30,
                        color: Colors.blue,
                      ),
                      Container(
                        height: 80,
                        width: 30,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
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