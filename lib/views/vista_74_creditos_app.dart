import 'package:flutter/material.dart';

class CreditosAppView extends StatelessWidget {
  const CreditosAppView({super.key});

  // Datos del equipo (Paso 2 del flujo)
  final List<Map<String, String>> equipo = const [
    {"nombre": "Fabiana", "rol": "Líder de Proyecto & Analista"},
    {"nombre": "Pablo", "rol": "Desarrollador Frontend & UI"},
    {"nombre": "Equipo SDAG", "rol": "Arquitectura de Software"},
  ];

  void _mostrarRol(BuildContext context, String nombre, String rol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(rol),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar", style: TextStyle(color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Acerca de la App', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo o Icono de la App
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
                  ],
                ),
                child: const Icon(Icons.apps_rounded, size: 80, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sistema de Gestión SDAG",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const Text(
              "Versión 2.4.0 (Build 102)", // Paso 3 del flujo
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AUTORÍA Y EQUIPO",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1),
                  ),
                  const SizedBox(height: 15),

                  // Lista interactiva del equipo (E74.1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25), // Radio 25px
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: equipo.map((persona) {
                        return ListTile(
                          title: Text(persona["nombre"]!, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFF2563EB)),
                          onTap: () => _mostrarRol(context, persona["nombre"]!, persona["rol"]!),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    "LEGAL",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1),
                  ),
                  const SizedBox(height: 15),

                  // Sección de Licencia (Paso 4 del flujo)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Licencia de Uso", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text(
                          "Copyright © 2026. Todos los derechos reservados. El uso de esta plataforma está sujeto a los términos de servicio para conductores y personal autorizado.",
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}