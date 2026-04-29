import 'package:flutter/material.dart';

class ClimaRutaView extends StatelessWidget {
  const ClimaRutaView({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos estáticos simulando la consulta a una API
    const String temperatura = "24°C";
    const String estadoClima = "Lluvia Ligera";
    const bool hayAlerta = true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Estado del Clima', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB), // Azul Primario
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con degradado simulado y temperatura
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  const Icon(Icons.cloud_sync_outlined, color: Colors.white, size: 40),
                  const SizedBox(height: 15),
                  const Text(
                    temperatura,
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 64, 
                      fontWeight: FontWeight.w300
                    ),
                  ),
                  Text(
                    estadoClima.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70, 
                      fontSize: 16, 
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alerta de mal tiempo (Paso 3 del flujo)
                  if (hayAlerta)
                    Container(
                      margin: const EdgeInsets.only(bottom: 25),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 30),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "¡Alerta de Clima!",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                ),
                                Text(
                                  "Se detecta lluvia en la zona de Chosica. Reduzca la velocidad.",
                                  style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    "Pronóstico en la Ruta",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 15),

                  // Tarjetas de tramos de ruta (Estilo 25px)
                  _construirTramoClima("Lima Centro", "Despejado", "26°C", Icons.wb_sunny_outlined),
                  const SizedBox(height: 15),
                  _construirTramoClima("Santa Anita", "Nublado", "23°C", Icons.wb_cloudy_outlined),
                  const SizedBox(height: 15),
                  _construirTramoClima("Chosica", "Lluvia", "19°C", Icons.umbrella_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTramoClima(String lugar, String clima, String temp, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), // Radio 25px manual
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lugar, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(clima, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ],
          ),
          Text(temp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2563EB))),
        ],
      ),
    );
  }
}