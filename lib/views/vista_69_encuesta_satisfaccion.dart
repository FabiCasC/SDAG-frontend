import 'package:flutter/material.dart';

class EncuestaSatisfaccionView extends StatefulWidget {
  const EncuestaSatisfaccionView({super.key});

  @override
  State<EncuestaSatisfaccionView> createState() => _EncuestaSatisfaccionViewState();
}

class _EncuestaSatisfaccionViewState extends State<EncuestaSatisfaccionView> {
  // Estado local para capturar las respuestas
  int calificacionPuntualidad = 0;
  int calificacionSeguridad = 0;
  final TextEditingController controladorComentario = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Encuesta de Satisfacción', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB), // Azul Primario
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            // Icono corregido (rate_review existe en todo Flutter)
            const Icon(Icons.rate_review, size: 70, color: Color(0xFF2563EB)),
            const SizedBox(height: 20),
            const Text(
              "Tu opinión nos ayuda a crecer",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Por favor, responde estas 3 preguntas. Tus respuestas son totalmente anónimas.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
            const SizedBox(height: 35),

            // Pregunta 1
            _construirTarjetaEncuesta(
              "1. ¿Cómo calificarías la puntualidad del servicio?",
              _construirSelectorEstrellas(calificacionPuntualidad, (valor) {
                setState(() => calificacionPuntualidad = valor);
              }),
            ),

            // Pregunta 2
            _construirTarjetaEncuesta(
              "2. ¿Qué tan seguro te sentiste con la conducción?",
              _construirSelectorEstrellas(calificacionSeguridad, (valor) {
                setState(() => calificacionSeguridad = valor);
              }),
            ),

            // Pregunta 3
            _construirTarjetaEncuesta(
              "3. Comentarios o sugerencias de mejora:",
              TextField(
                controller: controladorComentario,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Escribe tu mensaje aquí...",
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Botón de Envío (Naranja Acción)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Encuesta enviada. ¡Gracias por participar!"),
                      backgroundColor: Color(0xFF2563EB),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: const Text(
                  "ENVIAR COMENTARIOS",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar", style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaEncuesta(String titulo, Widget contenido) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
          const SizedBox(height: 15),
          contenido,
        ],
      ),
    );
  }

  Widget _construirSelectorEstrellas(int calificacion, Function(int) alCambiar) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < calificacion ? Icons.star : Icons.star_border,
            color: const Color(0xFFF97316),
            size: 40,
          ),
          onPressed: () => alCambiar(index + 1),
        );
      }),
    );
  }
}