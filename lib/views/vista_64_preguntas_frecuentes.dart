import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Preguntas Frecuentes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PreguntasFrecuentesPage(),
    );
  }
}

class PreguntasFrecuentesPage extends StatefulWidget {
  @override
  _PreguntasFrecuentesPageState createState() =>
      _PreguntasFrecuentesPageState();
}

class _PreguntasFrecuentesPageState extends State<PreguntasFrecuentesPage> {
  // Lista de preguntas y respuestas frecuentes
  final List<Map<String, String>> faqData = [
    {
      "pregunta": "¿Cómo registro una unidad en el sistema?",
      "respuesta": "Para registrar una unidad, ve a la sección 'Mis Unidades' y haz clic en 'Registrar nueva unidad'. Luego completa los campos requeridos."
    },
    {
      "pregunta": "¿Cómo puedo ver los horarios de salida?",
      "respuesta": "Puedes ver los horarios de salida en la sección 'Horarios', donde podrás consultar las salidas programadas para los próximos días."
    },
    {
      "pregunta": "¿Qué hacer si no puedo encontrar un conductor?",
      "respuesta": "Si no puedes encontrar un conductor, asegúrate de que el filtro de búsqueda esté correctamente configurado. Si el problema persiste, contacta al soporte."
    },
    {
      "pregunta": "¿Cómo activar el modo nocturno?",
      "respuesta": "Para activar el modo nocturno, ve a la sección de configuración y activa la opción 'Modo Nocturno'. Esto ajustará la interfaz para un uso más cómodo en condiciones de poca luz."
    },
    {
      "pregunta": "¿Dónde puedo ver mis pagos y facturas?",
      "respuesta": "Puedes ver todos tus pagos y facturas en la sección 'Historial de Pagos', donde podrás descargar los documentos en formato PDF."
    },
  ];

  // Controlador para el expandido de preguntas
  final List<bool> _expanded = List.generate(5, (index) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preguntas Frecuentes'),
        backgroundColor: Color(0xFF2563EB), // Azul Primario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Título de la sección
            Text(
              'Consulta nuestras preguntas frecuentes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Lista de preguntas frecuentes
            Expanded(
              child: ListView.builder(
                itemCount: faqData.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            faqData[index]["pregunta"]!,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(
                            _expanded[index]
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          onTap: () {
                            setState(() {
                              _expanded[index] = !_expanded[index];
                            });
                          },
                        ),
                        if (_expanded[index])
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              faqData[index]["respuesta"]!,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                      ],
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