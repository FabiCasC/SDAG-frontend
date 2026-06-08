import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Reservar Asientos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      home: ReservarAsientosPage(),
    );
  }
}

class ReservarAsientosPage extends StatefulWidget {
  @override
  _ReservarAsientosPageState createState() => _ReservarAsientosPageState();
}

class _ReservarAsientosPageState extends State<ReservarAsientosPage> {
  // Lista de asientos (6 asientos en total)
  final List<bool> _asientosSeleccionados = [false, false, false, false, false, false];
  final double precioPorAsiento = 15.0; // Precio por asiento

  int _totalSeleccionados = 0;

  void _actualizarTotal() {
    setState(() {
      _totalSeleccionados = _asientosSeleccionados.where((asiento) => asiento).toList().length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservar Asientos'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              'Selecciona hasta 4 asientos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 20),
            // Selección de asientos
            Expanded(
              child: ListView.builder(
                itemCount: _asientosSeleccionados.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Asiento ${index + 1}'),
                    trailing: Checkbox(
                      value: _asientosSeleccionados[index],
                      onChanged: (_totalSeleccionados < 4 || _asientosSeleccionados[index])
                          ? (bool? value) {
                        setState(() {
                          _asientosSeleccionados[index] = value!;
                          _actualizarTotal();
                        });
                      }
                          : null, // Deshabilita el checkbox si ya se han seleccionado 4 asientos
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            // Mostrar total
            Text(
              'Total Asientos Seleccionados: $_totalSeleccionados',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Total a pagar: S/ ${(_totalSeleccionados * precioPorAsiento).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Botón de pago
            ElevatedButton(
              onPressed: _totalSeleccionados > 0
                  ? () {
                // Lógica de pago
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Pago Realizado'),
                    content: Text('El pago por $_totalSeleccionados asiento(s) ha sido procesado con éxito.'),
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
              }
                  : null, // Deshabilitar el botón si no hay asientos seleccionados
              child: Text('Realizar Pago'),
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
