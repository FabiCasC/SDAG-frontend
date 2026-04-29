import 'package:flutter/material.dart';

class ConfiguracionAudioView extends StatefulWidget {
  const ConfiguracionAudioView({super.key});

  @override
  State<ConfiguracionAudioView> createState() => _ConfiguracionAudioViewState();
}

class _ConfiguracionAudioViewState extends State<ConfiguracionAudioView> {
  // Estado para el tono seleccionado
  String tonoSeleccionado = "Predeterminado";

  // Lista de tonos simulados
  final List<Map<String, String>> tonos = [
    {"nombre": "Predeterminado", "desc": "Sonido estándar del sistema"},
    {"nombre": "Alerta Suave", "desc": "Ideal para notificaciones de ruta"},
    {"nombre": "Campana", "desc": "Sonido claro para nuevos pasajeros"},
    {"nombre": "Digital", "desc": "Tono moderno y corto"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ajustes de Audio', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Cabecera informativa
          Container(
            width: double.infinity,
            color: const Color(0xFF2563EB),
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
            child: const Text(
              "Personaliza los sonidos de alerta para tus notificaciones de viaje.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),

          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -25),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: tonos.length,
                  itemBuilder: (context, index) {
                    final tono = tonos[index];
                    final esSeleccionado = tonoSeleccionado == tono['nombre'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: esSeleccionado ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: esSeleccionado ? const Color(0xFF2563EB).withOpacity(0.1) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: esSeleccionado ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          ),
                        ),
                        title: Text(
                          tono['nombre']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: esSeleccionado ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(tono['desc']!),
                        trailing: esSeleccionado 
                          ? const Icon(Icons.check_circle, color: Color(0xFF2563EB))
                          : const Icon(Icons.play_circle_outline, color: Color(0xFF64748B)),
                        onTap: () {
                          setState(() {
                            tonoSeleccionado = tono['nombre']!;
                          });
                          // Simulación de reproducción de sonido
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Reproduciendo prueba: ${tono['nombre']}"),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF1E293B),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Botón Guardar
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("GUARDAR PREFERENCIAS", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}