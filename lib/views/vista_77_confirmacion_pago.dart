import 'package:flutter/material.dart';

class ConfirmacionPagoView extends StatefulWidget {
  const ConfirmacionPagoView({super.key});

  @override
  State<ConfirmacionPagoView> createState() => _ConfirmacionPagoViewState();
}

class _ConfirmacionPagoViewState extends State<ConfirmacionPagoView> {
  bool pagoRecibido = false;
  final String monto = "S/ 15.50";

  void simularRecepcionPago() async {
    // 1. Simulación de red
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;

    setState(() {
      pagoRecibido = true;
    });

    // 2. Feedback nativo (Kaching simulado con SnackBar)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("¡Dinero recibido! Sonido 'Kaching' ejecutado"),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Confirmación de Pago', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Círculo de estado
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: pagoRecibido ? const Color(0xFFDCFCE7) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: pagoRecibido ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                    width: 3,
                  ),
                ),
                child: Icon(
                  pagoRecibido ? Icons.check_circle_rounded : Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: pagoRecibido ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                ),
              ),
              
              const SizedBox(height: 30),
              
              if (pagoRecibido) ...[
                const Text(
                  "¡COBRO EXITOSO!",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  monto,
                  style: const TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.bold, // Nativo y seguro
                    color: Color(0xFF1E293B),
                  ),
                ),
              ] else ...[
                const Text(
                  "Esperando validación...",
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
              ],

              const SizedBox(height: 50),

              // Botones de acción
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: pagoRecibido ? () => Navigator.pop(context) : simularRecepcionPago,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pagoRecibido ? const Color(0xFFF97316) : const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    pagoRecibido ? "CONTINUAR RUTA" : "SIMULAR COBRO",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}