import 'package:flutter/material.dart';

class AvisoActualizacionView extends StatefulWidget {
  const AvisoActualizacionView({super.key});

  @override
  State<AvisoActualizacionView> createState() => _AvisoActualizacionViewState();
}

class _AvisoActualizacionViewState extends State<AvisoActualizacionView> {
  // Simulación de estados del servidor
  bool hayNuevaVersion = false;
  bool esCritica = true; // Si es true, bloquea la app (E78.1)

  @override
  void initState() {
    super.initState();
    _comprobarVersion();
  }

  void _comprobarVersion() async {
    // 1. El sistema consulta versión en el server (Simulado)
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        hayNuevaVersion = true; // 2. Detecta que hay una nueva
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sistema de Actualizaciones', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Pantalla de fondo (Simulando la app normal)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_done_outlined, size: 80, color: Color(0xFF94A3B8)),
                const SizedBox(height: 20),
                Text(
                  hayNuevaVersion ? "Actualización pendiente..." : "Buscando actualizaciones...",
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // 3. El sistema muestra aviso obligatorio/opcional (Overlay)
          if (hayNuevaVersion)
            Container(
              color: Colors.black.withOpacity(0.7), // Bloqueo de fondo
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25), // Radio nativo 25px
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.system_update_rounded, size: 60, color: Color(0xFF2563EB)),
                      const SizedBox(height: 20),
                      const Text(
                        "Nueva versión disponible",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        esCritica 
                          ? "Esta actualización es obligatoria para seguir operando en la ruta." 
                          : "Hay mejoras disponibles para tu navegación.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 30),
                      
                      // 4. Redirige a la descarga del archivo (Botón principal)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Redirigiendo a descarga de APK...")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316), // Naranja acción
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("ACTUALIZAR AHORA", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      // Si no es crítica, permite omitir
                      if (!esCritica)
                        TextButton(
                          onPressed: () => setState(() => hayNuevaVersion = false),
                          child: const Text("Recordar más tarde", style: TextStyle(color: Color(0xFF64748B))),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}