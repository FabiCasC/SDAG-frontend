import 'package:flutter/material.dart';

class RedesSocialesView extends StatelessWidget {
  const RedesSocialesView({super.key});

  // Simulación de redirección (Paso 2 y 3 del flujo)
  void _abrirEnlace(BuildContext contexto, String plataforma) {
    ScaffoldMessenger.of(contexto).showSnackBar(
      SnackBar(
        content: Text("Abriendo navegador externo: oficial.com/$plataforma"),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Redes Sociales', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner decorativo
          Container(
            width: double.infinity,
            color: const Color(0xFF2563EB),
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
            child: const Text(
              "Conéctate con nuestra comunidad y mantente al tanto de las novedades.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(25),
                  children: [
                    const Text(
                      "NUESTROS PERFILES",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1),
                    ),
                    const SizedBox(height: 20),

                    // Icono de Facebook (Paso 1 del flujo)
                    _construirBotonRedSocial(
                      context,
                      "Facebook",
                      "Visita nuestra página oficial",
                      Icons.facebook,
                      const Color(0xFF1877F2),
                    ),
                    const SizedBox(height: 15),

                    // Icono de Instagram (Criterio de aceptación)
                    _construirBotonRedSocial(
                      context,
                      "Instagram",
                      "Mira nuestras fotos y noticias",
                      Icons.camera_alt_rounded,
                      const Color(0xFFE4405F),
                    ),
                    const SizedBox(height: 15),

                    // Opción adicional para soporte vía redes
                    _construirBotonRedSocial(
                      context,
                      "LinkedIn",
                      "Perfil profesional de la empresa",
                      Icons.business_center_rounded,
                      const Color(0xFF0A66C2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Pie de página (Manual de estilo)
          const Padding(
            padding: EdgeInsets.all(30.0),
            child: Text(
              "SDAG Corporativo © 2026",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotonRedSocial(BuildContext contexto, String nombre, String subtexto, IconData icono, Color colorIcono) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), // Radio 25px
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorIcono.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: colorIcono, size: 28),
        ),
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        subtitle: Text(subtexto, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.open_in_new_rounded, color: Color(0xFF94A3B8), size: 20),
        onTap: () => _abrirEnlace(contexto, nombre.toLowerCase()),
      ),
    );
  }
}