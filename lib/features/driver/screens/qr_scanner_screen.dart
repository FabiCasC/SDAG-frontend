import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';

/// Pantalla de escaneo de QR para el conductor.
/// Permite verificar el abordaje de pasajeros leyendo su código QR.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  /// Controlador de la cámara y el escáner
  final MobileScannerController _controller = MobileScannerController();

  /// Bandera para evitar procesar múltiples escaneos seguidos
  bool _escaneado = false;

  /// Guarda el valor del último QR leído
  String? _resultadoQr;

  /// null = sin escanear, true = QR válido, false = QR inválido
  bool? _esValido;

  /// Se ejecuta automáticamente cada vez que la cámara detecta un código QR.
  /// Solo procesa el primero e ignora los siguientes hasta reiniciar.
  void _onDetect(BarcodeCapture capture) {
    // Si ya se escaneó uno, ignorar los siguientes
    if (_escaneado) return;

    // Tomar el primer código detectado
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final qrToken = barcode.rawValue!;

    // Marcar como escaneado y detener la cámara
    setState(() {
      _escaneado = true;
      _resultadoQr = qrToken;
    });

    _controller.stop();

    // Proceder a validar el token leído
    _validarQr(qrToken);
  }

  /// Valida el token del QR escaneado.
  /// 
  /// Por ahora es una simulación local: cualquier QR que empiece
  /// con 'SDAG-' se considera válido.
  /// Cuando se integre Supabase, aquí va la llamada RPC real que
  /// consultará la tabla Manifiesto_Electronico y cambiará el
  /// estado del pasajero a "Subió".
  void _validarQr(String token) {
    final esValido = token.startsWith('SDAG-');
    setState(() {
      _esValido = esValido;
    });
    _mostrarResultado(esValido, token);
  }

  /// Muestra un diálogo con el resultado del escaneo.
  /// Si es válido, permite confirmar el abordaje o escanear otro.
  /// Si es inválido, solo permite intentar de nuevo.
  void _mostrarResultado(bool esValido, String token) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // El conductor debe tomar una acción
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              // Ícono verde si válido, rojo si inválido
              Icon(
                esValido
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: esValido ? AppColors.success : AppColors.error,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(esValido ? 'QR Válido' : 'QR Inválido'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensaje según resultado
              Text(
                esValido
                    ? 'Pasajero verificado. Abordaje registrado en el manifiesto.'
                    : 'QR no válido o ya usado. No se permite el abordaje.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              // Muestra el token leído para referencia
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Token: $token',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            // Botón de confirmar abordaje solo aparece si el QR es válido
            if (esValido)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context).pop(true); // Regresa a monitor de carga con éxito
                },
                child: const Text('Confirmar abordaje'),
              ),
            // Botón para escanear otro o intentar de nuevo
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reiniciarEscaner();
              },
              child: Text(esValido ? 'Escanear otro' : 'Intentar de nuevo'),
            ),
          ],
        );
      },
    );
  }

  /// Reinicia el escáner para permitir leer un nuevo QR.
  void _reiniciarEscaner() {
    setState(() {
      _escaneado = false;
      _resultadoQr = null;
      _esValido = null;
    });
    _controller.start();
  }

  /// Libera el controlador de la cámara al salir de la pantalla.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR de pasajero'),
        actions: [
          // Botón para encender/apagar la linterna
          IconButton(
            icon: const Icon(Icons.flashlight_on_rounded),
            tooltip: 'Linterna',
            onPressed: () => _controller.toggleTorch(),
          ),
          // Botón para cambiar entre cámara frontal y trasera
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Cambiar cámara',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vista principal de la cámara con detección de QR
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Marco visual que guía al conductor dónde apuntar
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  // Azul = esperando, Verde = válido, Rojo = inválido
                  color: _esValido == null
                      ? AppColors.primaryBlue
                      : _esValido!
                          ? AppColors.success
                          : AppColors.error,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Texto de instrucción en la parte inferior
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _escaneado ? 'Procesando...' : 'Apunta al QR del pasajero',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}