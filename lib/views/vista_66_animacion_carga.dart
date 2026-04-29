import 'package:flutter/material.dart';

class LoadingBrandingView extends StatefulWidget {
  const LoadingBrandingView({super.key});

  @override
  State<LoadingBrandingView> createState() => _LoadingBrandingViewState();
}

class _LoadingBrandingViewState extends State<LoadingBrandingView> {
  @override
  void initState() {
    super.initState();
    // REQUERIMIENTO 1: El sistema inicia proceso pesado (Simulado con 3 segundos)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // REQUERIMIENTO 3: El sistema oculta la animación al recibir respuesta
        // REQUERIMIENTO 4: Se renderizan los datos (Navega a la siguiente vista)
        Navigator.pop(context); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // REQUERIMIENTO 2: El sistema muestra el logo animado (Branding)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB), // Azul SDAG
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus, 
                size: 80, 
                color: Colors.white
              ),
            ),
            const SizedBox(height: 30),
            // Indicador de carga personalizado
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              strokeWidth: 5,
            ),
            const SizedBox(height: 20),
            const Text(
              "PROCESANDO DATOS SDAG",
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}