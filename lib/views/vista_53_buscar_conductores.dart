import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Buscador de Conductores',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      home: BuscarConductoresPage(),
    );
  }
}

class BuscarConductoresPage extends StatefulWidget {
  @override
  _BuscarConductoresPageState createState() => _BuscarConductoresPageState();
}

class _BuscarConductoresPageState extends State<BuscarConductoresPage> {
  // Lista de conductores simulados
  final List<Map<String, String>> conductores = [
    {"nombre": "Juan Pérez", "dni": "12345678", "vehiculo": "Toyota Hiace 2022"},
    {"nombre": "Ana Gómez", "dni": "23456789", "vehiculo": "Hyundai H1 2021"},
    {"nombre": "Luis Martínez", "dni": "34567890", "vehiculo": "Nissan NV350 2020"},
    {"nombre": "Carlos Sánchez", "dni": "45678901", "vehiculo": "Chevrolet Express 2021"},
  ];

  String _searchQuery = "";  // Variable para almacenar la consulta de búsqueda

  // Función para filtrar los conductores por nombre o DNI
  List<Map<String, String>> _filtrarConductores() {
    return conductores.where((conductor) {
      return conductor["nombre"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          conductor["dni"]!.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscador de Conductores'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Campo de texto para la búsqueda
            TextField(
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              decoration: InputDecoration(
                labelText: 'Buscar por Nombre o DNI',
                hintText: 'Ingresa el nombre o DNI del conductor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 20),
            // Mostrar resultados de la búsqueda
            Expanded(
              child: _searchQuery.isEmpty
                  ? Center(child: Text('Ingresa un nombre o DNI para buscar'))
                  : ListView.builder(
                itemCount: _filtrarConductores().length,
                itemBuilder: (context, index) {
                  var conductor = _filtrarConductores()[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(conductor["nombre"]!),
                      subtitle: Text('DNI: ${conductor["dni"]}\nVehículo: ${conductor["vehiculo"]}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
