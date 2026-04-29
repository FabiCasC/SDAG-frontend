import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Registro de Objetos Perdidos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RegistroObjetosPerdidosPage(),
    );
  }
}

class RegistroObjetosPerdidosPage extends StatefulWidget {
  @override
  _RegistroObjetosPerdidosPageState createState() =>
      _RegistroObjetosPerdidosPageState();
}

class _RegistroObjetosPerdidosPageState
    extends State<RegistroObjetosPerdidosPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  // Lista para almacenar los objetos perdidos registrados
  List<Map<String, String>> objetosPerdidos = [];

  // Función para registrar un objeto perdido
  void _registrarObjeto() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        objetosPerdidos.add({
          "nombre": _nombreController.text,
          "descripcion": _descripcionController.text,
          "ubicacion": _ubicacionController.text,
        });
      });

      // Limpiar los campos del formulario después de registrar
      _nombreController.clear();
      _descripcionController.clear();
      _ubicacionController.clear();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Objeto perdido registrado con éxito')));
    }
  }

  // Función para buscar objetos perdidos
  List<Map<String, String>> _buscarObjetos(String query) {
    return objetosPerdidos
        .where((objeto) =>
    objeto["nombre"]!.toLowerCase().contains(query.toLowerCase()) ||
        objeto["descripcion"]!
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Objetos Perdidos'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              'Formulario de Registro de Objetos Perdidos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Formulario para registrar objeto perdido
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  // Campo de texto para el nombre del objeto
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del objeto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el nombre del objeto';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Campo de texto para la descripción del objeto
                  TextFormField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción del objeto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una descripción';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Campo de texto para la ubicación del objeto
                  TextFormField(
                    controller: _ubicacionController,
                    decoration: InputDecoration(
                      labelText: 'Ubicación del objeto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la ubicación';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Botón de registrar objeto
                  ElevatedButton(
                    onPressed: _registrarObjeto,
                    child: Text('Registrar Objeto Perdido'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            // Título de la sección de búsqueda
            Text(
              'Buscar Objetos Perdidos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Campo de búsqueda
            TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  // Actualizar la lista con los resultados de la búsqueda
                });
              },
            ),
            SizedBox(height: 20),
            // Lista de objetos perdidos
            Expanded(
              child: ListView.builder(
                itemCount: _buscarObjetos('').length,
                itemBuilder: (context, index) {
                  var objeto = _buscarObjetos('')[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(objeto["nombre"]!),
                      subtitle: Text('Descripción: ${objeto["descripcion"]}\nUbicación: ${objeto["ubicacion"]}'),
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