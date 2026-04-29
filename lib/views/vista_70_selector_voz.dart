import 'package:flutter/material.dart';

class SelectorVozView extends StatefulWidget {
  const SelectorVozView({super.key});

  @override
  State<SelectorVozView> createState() => _SelectorVozViewState();
}

class _SelectorVozViewState extends State<SelectorVozView> {
  // Estado para controlar la voz seleccionada y el progreso de descarga
  String vozSeleccionada = "Femenina";
  bool descargando = false;
  double progresoDescarga = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Asistente de Voz', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB), // Azul Primario
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Cabecera con el estado actual
          Container(
            width: double.infinity,
            color: const Color(0xFF2563EB),
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
            child: const Text(
              "Elige el timbre de voz para las instrucciones de navegación y alertas.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
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
                    _construirOpcionVoz(
                      "Voz Femenina", 
                      "Voz clara y natural para el día a día", 
                      Icons.record_voice_over_outlined
                    ),
                    const SizedBox(height: 20),
                    _construirOpcionVoz(
                      "Voz Masculina", 
                      "Voz profunda con énfasis en alertas", 
                      Icons.keyboard_voice_outlined
                    ),
                    
                    if (descargando) ...[
                      const SizedBox(height: 40),
                      const Text(
                        "Descargando paquete de voz...",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progresoDescarga,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: const Color(0xFF2563EB),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Botón de Prueba de Audio (Naranja Acción)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: descargando ? null : _reproducirPrueba,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text("REPRODUCIR PRUEBA", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ),

          // Botón Aplicar
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: descargando ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("APLICAR CAMBIOS", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirOpcionVoz(String nombre, String subtexto, IconData icono) {
    bool seleccionada = vozSeleccionada == (nombre.contains("Femenina") ? "Femenina" : "Masculina");

    return GestureDetector(
      onTap: () => _iniciarDescarga(nombre.contains("Femenina") ? "Femenina" : "Masculina"),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: seleccionada ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: seleccionada ? const Color(0xFF2563EB).withOpacity(0.1) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: seleccionada ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtexto, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ),
            if (seleccionada)
              const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  void _iniciarDescarga(String tipo) {
    if (vozSeleccionada == tipo) return;
    
    setState(() {
      descargando = true;
      progresoDescarga = 0.0;
    });

    // Simulación de descarga por pasos
    Future.delayed(const Duration(milliseconds: 500), () => setState(() => progresoDescarga = 0.3));
    Future.delayed(const Duration(milliseconds: 1200), () => setState(() => progresoDescarga = 0.7));
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        vozSeleccionada = tipo;
        descargando = false;
        progresoDescarga = 1.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paquete de voz listo"), backgroundColor: Color(0xFF2563EB))
      );
    });
  }

  void _reproducirPrueba() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reproduciendo prueba de voz $vozSeleccionada..."),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}