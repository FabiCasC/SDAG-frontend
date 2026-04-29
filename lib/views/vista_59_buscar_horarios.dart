import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Buscador de Horarios',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BuscarHorariosPage(),
    );
  }
}

class BuscarHorariosPage extends StatefulWidget {
  @override
  _BuscarHorariosPageState createState() => _BuscarHorariosPageState();
}

class _BuscarHorariosPageState extends State<BuscarHorariosPage> {
  final TextEditingController _searchController = TextEditingController();

  // Simulación de horarios de salida de los terminales
  final List<Map<String, String>> horarios = [
    {"terminal": "Terminal 1", "hora": "08:00 AM", "destino": "Ciudad A"},
    {"terminal": "Terminal 2", "hora": "09:30 AM", "destino": "Ciudad B"},
    {"terminal": "Terminal 1", "hora": "10:00 AM", "destino": "Ciudad C"},
    {"terminal": "Terminal 3", "hora": "11:15 AM", "destino": "Ciudad D"},
    {"terminal": "Terminal 2", "hora": "12:00 PM", "destino": "Ciudad E"},
  ];

  // Función para buscar los horarios
  List<Map<String, String>> _buscarHorarios(String query) {
    return horarios.where((horario) {
      return horario["terminal"]!.toLowerCase().contains(query.toLowerCase()) ||
          horario["hora"]!.toLowerCase().contains(query.toLowerCase()) ||
          horario["destino"]!.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscador de Horarios de Salida'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Campo de texto para la búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por Terminal, Hora o Destino',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  // Actualizar los resultados de búsqueda
                });
              },
            ),
            SizedBox(height: 20),
            // Mostrar resultados de la búsqueda
            Expanded(
              child: _searchController.text.isEmpty
                  ? Center(child: Text('Ingresa un terminal, hora o destino para buscar'))
                  : ListView.builder(
                itemCount: _buscarHorarios(_searchController.text).length,
                itemBuilder: (context, index) {
                  var horario = _buscarHorarios(_searchController.text)[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('Terminal: ${horario["terminal"]}'),
                      subtitle: Text('Hora: ${horario["hora"]}\nDestino: ${horario["destino"]}'),
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