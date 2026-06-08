import 'package:flutter/material.dart';

class SoporteTecnicoView extends StatefulWidget {
  const SoporteTecnicoView({super.key});

  @override
  State<SoporteTecnicoView> createState() => _SoporteTecnicoViewState();
}

class _SoporteTecnicoViewState extends State<SoporteTecnicoView> {
  final TextEditingController _controladorError = TextEditingController();
  bool _enviando = false;

  // Simulación de datos técnicos (Criterio de aceptación)
  final String _infoDispositivo = "Samsung Galaxy S22 - Android 13";
  final String _versionApp = "v2.4.0-build.102";

  void _enviarReporte() async {
    setState(() => _enviando = true);
    
    // Simulación de flujo de eventos (Puntos 2, 3 y 4)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    setState(() => _enviando = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ticket #8293 recibido. Soporte técnico revisará su caso."),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Soporte Técnico', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Informativo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Sus reportes ayudan a mejorar la plataforma. El sistema adjuntará automáticamente un log técnico del error.",
                      style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            const Text(
              "Descripción del problema",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            
            // Campo de texto para el error (Paso 1 del flujo)
            TextField(
              controller: _controladorError,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "Describa el error detectado o su sugerencia...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25), // Radio de 25px
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Sección de Adjuntos Automáticos (Criterios de Aceptación)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _filaDetalleTecnico(Icons.phone_android, "Dispositivo", _infoDispositivo),
                  const Divider(height: 30),
                  _filaDetalleTecnico(Icons.terminal_rounded, "Versión App", _versionApp),
                  const Divider(height: 30),
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 10),
                      const Text("Log técnico generado", style: TextStyle(color: Color(0xFF64748B))),
                      const Spacer(),
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botón de Envío
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarReporte,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316), // Naranja Acción
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: _enviando 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ENVIAR REPORTE", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaDetalleTecnico(IconData icono, String etiqueta, String valor) {
    return Row(
      children: [
        Icon(icono, color: const Color(0xFF64748B), size: 20),
        const SizedBox(width: 10),
        Text(etiqueta, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        const Spacer(),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
      ],
    );
  }
}
