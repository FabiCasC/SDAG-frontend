import 'package:flutter/material.dart';

class ZoomMapaView extends StatefulWidget {
  const ZoomMapaView({super.key});

  @override
  State<ZoomMapaView> createState() => _ZoomMapaViewState();
}

class _ZoomMapaViewState extends State<ZoomMapaView> {
  // Estado para simular la velocidad y el nivel de zoom
  double velocidadActual = 0.0;
  double nivelZoom = 1.0; // 1.0 es cerca, 0.5 es lejos

  void _actualizarVelocidad(double nuevaVelocidad) {
    setState(() {
      velocidadActual = nuevaVelocidad;
      // Lógica del requerimiento: > 40km/h aleja el zoom (Paso 1 y 2)
      if (nuevaVelocidad > 40) {
        nivelZoom = 0.6; 
      } else if (nuevaVelocidad == 0) {
        nivelZoom = 1.2; // Muy cerca al detenerse (Paso 3)
      } else {
        nivelZoom = 1.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mapa de Seguimiento', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Área del Mapa (Simulada)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(25), // Radio 25px
                border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Stack(
                  children: [
                    // Fondo de cuadrícula simulando mapa
                    AnimatedScale(
                      scale: nivelZoom,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      child: Center(
                        child: Icon(
                          Icons.map_rounded, 
                          size: 500, 
                          color: Colors.blueGrey.withOpacity(0.1)
                        ),
                      ),
                    ),
                    // Indicador del vehículo (Punto central fijo)
                    const Center(
                      child: Icon(Icons.navigation_rounded, color: Color(0xFF2563EB), size: 40),
                    ),
                    // Etiqueta de Zoom actual
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Zoom: ${nivelZoom == 0.6 ? 'Alejado' : 'Cercano'}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Panel de Control de Velocidad (Para probar el requerimiento)
          Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "SIMULADOR DE VELOCIDAD",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      velocidadActual.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const Text(" km/h", style: TextStyle(fontSize: 20, color: Color(0xFF64748B))),
                  ],
                ),
                Slider(
                  value: velocidadActual,
                  min: 0,
                  max: 100,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) => _actualizarVelocidad(val),
                ),
                const SizedBox(height: 10),
                // Botón de Acción (Naranja)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("VOLVER A AJUSTES", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}