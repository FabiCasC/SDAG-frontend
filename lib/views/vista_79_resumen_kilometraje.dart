import 'package:flutter/material.dart';

class ResumenKilometrajeView extends StatelessWidget {
  const ResumenKilometrajeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos calculados por el sistema (Flujo 1, 2 y 3)
    const double kilometrajeTotal = 145.8;
    const double kilometrajeConPasajeros = 132.4;
    const double kilometrajeVacio = 13.4;
    const int viajesFinalizados = 12;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Resumen de Jornada', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con el dato principal (Criterio de aceptación)
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
                  const Text(
                    "DISTANCIA TOTAL RECORRIDA",
                    style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        kilometrajeTotal.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 64, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "KM",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Desglose de Kilometraje",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 20),

                  // Tarjeta Detallada (Diseño 25px)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _construirFilaDato(
                          Icons.people_alt_outlined, 
                          "Tramos con pasajeros", 
                          "$kilometrajeConPasajeros km", 
                          const Color(0xFF16A34A)
                        ),
                        const Divider(height: 30),
                        _construirFilaDato(
                          Icons.no_accounts_outlined, 
                          "Tramos sin pasajeros", 
                          "$kilometrajeVacio km", 
                          const Color(0xFF64748B)
                        ),
                        const Divider(height: 30),
                        _construirFilaDato(
                          Icons.route_outlined, 
                          "Total de viajes", 
                          "$viajesFinalizados servicios", 
                          const Color(0xFF2563EB)
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Nota informativa (Excepción E79.1)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_fix_high_rounded, color: Color(0xFF2563EB), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Sistema de filtrado GPS activo: Kilometraje optimizado automáticamente.",
                            style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botón Finalizar Turno (Naranja)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text(
                        "CERRAR JORNADA",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFilaDato(IconData icono, String etiqueta, String valor, Color colorIcono) {
    return Row(
      children: [
        Icon(icono, color: colorIcono, size: 24),
        const SizedBox(width: 15),
        Text(etiqueta, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
        const Spacer(),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
      ],
    );
  }
}