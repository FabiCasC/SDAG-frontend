import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Enviar Comprobante de Pago',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EnviarComprobantePage(),
    );
  }
}

class EnviarComprobantePage extends StatefulWidget {
  @override
  _EnviarComprobantePageState createState() => _EnviarComprobantePageState();
}

class _EnviarComprobantePageState extends State<EnviarComprobantePage> {
  final TextEditingController _emailController = TextEditingController();
  final String _comprobante = 'Comprobante de Pago: \n\nMonto: S/100\nFecha: 05/06/2026\nTicket No: 123456';

  // Función para simular el envío del comprobante por correo
  Future<void> _enviarComprobante() async {
    // Simulación de envío de correo
    await Future.delayed(Duration(seconds: 2)); // Simulando la espera de un correo real

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comprobante enviado con éxito')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enviar Comprobante de Pago'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              'Envía tu comprobante de pago al correo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Comprobante de pago
            Text(
              _comprobante,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // Campo para ingresar el correo
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'Ingresa tu correo electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 20),
            // Botón para enviar el comprobante por correo
            ElevatedButton(
              onPressed: _enviarComprobante,
              child: Text('Enviar Comprobante'),
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