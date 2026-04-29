import 'package:flutter/material.dart';

class ShareTripView extends StatelessWidget {
  const ShareTripView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fondo suave
      appBar: AppBar(
        title: const Text('Seguridad en Viaje', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB), // Azul Primario #2563EB
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabecera con el icono que acordamos
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_outlined, // Icono lineal acordado
                    size: 80,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const Text(
                    "Compartir Ubicación",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF1E293B)
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Envía tu ruta en tiempo real a tus contactos para que puedan seguir tu viaje de forma segura.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                  
                  const SizedBox(height: 35),

                  // Tarjeta de Información (Sin nombre de empresa)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.shield_outlined, "Protección de datos activa"),
                        const Divider(height: 30),
                        _buildDetailRow(Icons.map_outlined, "Ruta: Lima - Chosica"),
                        const Divider(height: 30),
                        _buildDetailRow(Icons.av_timer_rounded, "Enlace temporal de 2 horas"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
                  
                  // Botón de Acción Naranja (#F97316)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Generando enlace seguro..."),
                            backgroundColor: Color(0xFFF97316),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded),
                          SizedBox(width: 12),
                          Text("ENVIAR POR WHATSAPP", 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
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

  Widget _buildDetailRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 24),
        const SizedBox(width: 15),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15, 
            fontWeight: FontWeight.w500, 
            color: Color(0xFF1E293B)
          ),
        ),
      ],
    );
  }
}