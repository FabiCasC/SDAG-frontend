import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Mantenimiento Preventivo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MantenimientoPreventivoPage(),
    );
  }
}

class MantenimientoPreventivoPage extends StatefulWidget {
  @override
  _MantenimientoPreventivoPageState createState() => _MantenimientoPreventivoPageState();
}

class _MantenimientoPreventivoPageState extends State<MantenimientoPreventivoPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _cambioAceiteController = TextEditingController();
  final TextEditingController _revisionController = TextEditingController();

  // Simulación de datos de unidades y mantenimiento
  List<Map<String, String>> mantenimientoUnidades = [];

  // Función para registrar el mantenimiento
  void _registrarMantenimiento() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        mantenimientoUnidades.add({
          "unidad": _unidadController.text,
          "cambio_aceite": _cambioAceiteController.text,
          "revision": _revisionController.text,
        });
      });

      // Limpiar los campos del formulario después de registrar
      _unidadController.clear();
      _cambioAceiteController.clear();
      _revisionController.clear();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mantenimiento registrado con éxito')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Mantenimiento Preventivo'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              'Formulario de Registro de Mantenimiento Preventivo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Formulario para registrar el mantenimiento
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  // Campo de texto para el nombre de la unidad
                  TextFormField(
                    controller: _unidadController,
                    decoration: InputDecoration(
                      labelText: 'Nombre o Placa de la Unidad',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el nombre o placa de la unidad';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Campo de texto para la fecha de próximo cambio de aceite
                  TextFormField(
                    controller: _cambioAceiteController,
                    decoration: InputDecoration(
                      labelText: 'Fecha de Próximo Cambio de Aceite',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la fecha de próximo cambio de aceite';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.datetime,
                  ),
                  SizedBox(height: 16),
                  // Campo de texto para la fecha de próxima revisión
                  TextFormField(
                    controller: _revisionController,
                    decoration: InputDecoration(
                      labelText: 'Fecha de Próxima Revisión',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la fecha de próxima revisión';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.datetime,
                  ),
                  SizedBox(height: 20),
                  // Botón para registrar el mantenimiento
                  ElevatedButton(
                    onPressed: _registrarMantenimiento,
                    child: Text('Registrar Mantenimiento'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            // Título de la sección de listado de mantenimientos
            Text(
              'Mantenimientos Registrados',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Mostrar los mantenimientos registrados
            Expanded(
              child: ListView.builder(
                itemCount: mantenimientoUnidades.length,
                itemBuilder: (context, index) {
                  var mantenimiento = mantenimientoUnidades[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('Unidad: ${mantenimiento["unidad"]}'),
                      subtitle: Text(
                          'Cambio de Aceite: ${mantenimiento["cambio_aceite"]}\nPróxima Revisión: ${mantenimiento["revision"]}'),
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
//57