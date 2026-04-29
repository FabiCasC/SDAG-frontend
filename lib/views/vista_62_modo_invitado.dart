import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Modo Invitado',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ModoInvitadoPage(),
    );
  }
}

class ModoInvitadoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simulación de disponibilidad de unidades
    final List<Map<String, String>> unidadesDisponibles = [
      {"unidad": "Toyota Hiace 2022", "disponibilidad": "Disponible"},
      {"unidad": "Hyundai H1 2021", "disponibilidad": "Disponible"},
      {"unidad": "Nissan NV350 2020", "disponibilidad": "No disponible"},
      {"unidad": "Chevrolet Express 2021", "disponibilidad": "Disponible"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Modo Invitado - Disponibilidad de Unidades'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              'Consulta de Disponibilidad de Unidades',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Texto explicativo
            Text(
              'Como invitado, puedes consultar la disponibilidad de unidades sin necesidad de iniciar sesión.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // Mostrar la disponibilidad de las unidades
            Expanded(
              child: ListView.builder(
                itemCount: unidadesDisponibles.length,
                itemBuilder: (context, index) {
                  var unidad = unidadesDisponibles[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(unidad["unidad"]!),
                      subtitle: Text('Disponibilidad: ${unidad["disponibilidad"]}'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            // Botón para iniciar sesión
            ElevatedButton(
              onPressed: () {
                // Acción para ir a la pantalla de inicio de sesión
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Iniciar sesión para más opciones'),
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

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar Sesión'),
        backgroundColor: Color(0xFF2563EB),
      ),
      body: Center(
        child: Text(
          'Pantalla de inicio de sesión',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}