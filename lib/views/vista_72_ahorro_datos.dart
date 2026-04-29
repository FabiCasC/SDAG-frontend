import 'package:flutter/material.dart';

class AhorroDatosView extends StatefulWidget {
  const AhorroDatosView({super.key});

  @override
  State<AhorroDatosView> createState() => _AhorroDatosViewState();
}

class _AhorroDatosViewState extends State<AhorroDatosView> {
  // Estado para el interruptor principal
  bool modoAhorroActivo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gestión de Datos', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB), // Azul Primario
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner de estado de ahorro
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: modoAhorroActivo ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
            child: Column(
              children: [
                Icon(
                  modoAhorroActivo ? Icons.bolt_rounded : Icons.data_usage_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  modoAhorroActivo ? "MODO AHORRO ACTIVO" : "MODO ESTÁNDAR",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Text(
                  "Optimiza tu consumo de megas en ruta",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(25),
              children: [
                // Interruptor Principal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25), // Radio de 25px
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SwitchListTile(
                    title: const Text("Activar Ahorro de Datos", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    subtitle: const Text("Reduce el consumo de red un 40%"),
                    value: modoAhorroActivo,
                    activeColor: const Color(0xFF16A34A),
                    onChanged: (bool valor) {
                      setState(() {
                        modoAhorroActivo = valor;
                      });
                      _mostrarNotificacion(valor);
                    },
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  "ACCIONES DE OPTIMIZACIÓN",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1),
                ),
                const SizedBox(height: 15),

                // Lista de optimizaciones (Puntos 2, 3 y 4 del flujo)
                _construirItemOptimizacion(
                  Icons.map_outlined, 
                  "Calidad de Mapas", 
                  modoAhorroActivo ? "Baja (Solo vectores)" : "Alta (Satélite)",
                  modoAhorroActivo
                ),
                const SizedBox(height: 15),
                _construirItemOptimizacion(
                  Icons.sync_disabled_rounded, 
                  "Refresco de UI", 
                  modoAhorroActivo ? "Frecuencia reducida" : "Tiempo real",
                  modoAhorroActivo
                ),
                const SizedBox(height: 15),
                _construirItemOptimizacion(
                  Icons.image_not_supported_outlined, 
                  "Imágenes de Unidades", 
                  modoAhorroActivo ? "Desactivadas" : "Carga automática",
                  modoAhorroActivo
                ),
              ],
            ),
          ),

          // Botón de Guardar Preferencias (Naranja Acción)
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: const Text("GUARDAR AJUSTES", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemOptimizacion(IconData icono, String titulo, String estado, bool activo) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icono, color: activo ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
              Text(estado, style: TextStyle(color: activo ? const Color(0xFF16A34A) : const Color(0xFF64748B), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarNotificacion(bool activado) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(activado ? "Modo ahorro activado" : "Cargando elementos pesados..."),
        backgroundColor: activado ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}