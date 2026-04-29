import 'package:flutter/material.dart';
import 'dart:async';

class ParadaEmergenciaView extends StatefulWidget {
  const ParadaEmergenciaView({super.key});

  @override
  State<ParadaEmergenciaView> createState() => _ParadaEmergenciaViewState();
}

class _ParadaEmergenciaViewState extends State<ParadaEmergenciaView> {
  bool detenido = false;
  Timer? cronometro;
  int segundosTranscurridos = 0;

  // Formatear tiempo para el cronómetro
  String _formatearTiempo(int segundos) {
    int minutos = segundos ~/ 60;
    int restantes = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${restantes.toString().padLeft(2, '0')}';
  }

  void _alternarParada() {
    setState(() {
      detenido = !detenido;
    });

    if (detenido) {
      // 1. Chofer pulsa parada. 2. Marca GPS (Simulado). 3. Avisa pasajeros.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aviso enviado a pasajeros: 'Breve detención'"),
          backgroundColor: Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 4. Inicia registro de tiempo
      cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          segundosTranscurridos++;
        });
        
        // Excepción E80.1: Alerta si > 15 min (900 seg)
        if (segundosTranscurridos == 900) {
          _enviarAlertaDuenio();
        }
      });
    } else {
      cronometro?.cancel();
      _finalizarRegistro();
    }
  }

  void _enviarAlertaDuenio() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("ALERTA: Parada prolongada reportada al dueño"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _finalizarRegistro() {
    // Postcondición: Registro en log
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Parada Finalizada"),
        content: Text("Duración total: ${_formatearTiempo(segundosTranscurridos)}\nUbicación: Av. Chosica km 24\nETA de pasajeros reiniciado."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ACEPTAR"),
          ),
        ],
      ),
    );
    segundosTranscurridos = 0;
  }

  @override
  void dispose() {
    cronometro?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Parada Técnica', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: detenido ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: detenido ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 50),
                const SizedBox(height: 15),
                Text(
                  detenido ? "VEHÍCULO DETENIDO" : "ESTADO: EN RUTA",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("TIEMPO TRANSCURRIDO", style: TextStyle(color: Color(0xFF64748B), letterSpacing: 1.5)),
                  Text(
                    _formatearTiempo(segundosTranscurridos),
                    style: TextStyle(
                      fontSize: 80, 
                      fontWeight: FontWeight.bold, 
                      color: detenido ? const Color(0xFFDC2626) : const Color(0xFF1E293B)
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Botón de Acción Principal
                  GestureDetector(
                    onTap: _alternarParada,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: detenido ? const Color(0xFFDC2626) : const Color(0xFF2563EB), 
                          width: 8
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (detenido ? Colors.red : Colors.blue).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          detenido ? "FINALIZAR" : "INICIAR\nPARADA",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            color: detenido ? const Color(0xFFDC2626) : const Color(0xFF2563EB)
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}