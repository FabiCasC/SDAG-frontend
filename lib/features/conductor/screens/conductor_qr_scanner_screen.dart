import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/conductor_manifiesto_provider.dart';

class ConductorQrScannerScreen extends ConsumerStatefulWidget {
  const ConductorQrScannerScreen({super.key});

  @override
  ConsumerState<ConductorQrScannerScreen> createState() => _ConductorQrScannerScreenState();
}

class _ConductorQrScannerScreenState extends ConsumerState<ConductorQrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  bool _escaneando = true;
  bool _procesando = false;
  String? _resultado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.start());
    } else if (state == AppLifecycleState.paused) {
      unawaited(_controller.stop());
    }
  }

  Future<void> _reactivarEscanner({Duration delay = const Duration(seconds: 2)}) async {
    await Future<void>.delayed(delay);
    if (!mounted) return;
    setState(() {
      _escaneando = true;
      _resultado = null;
      _procesando = false;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_escaneando || _procesando) return;

    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final raw = barcode?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    setState(() {
      _escaneando = false;
      _procesando = true;
    });

    await _procesarQR(raw);
  }

  Future<void> _procesarQR(String qrValue) async {
    var reservaId = qrValue.contains('|') ? qrValue.split('|').first.trim() : qrValue.trim();
    if (reservaId.startsWith('res_')) {
      reservaId = reservaId.substring(4);
    }

    if (!_uuidRegex.hasMatch(reservaId)) {
      setState(() => _resultado = '❌ QR inválido — formato incorrecto');
      await _reactivarEscanner();
      return;
    }

    try {
      final reserva = await Supabase.instance.client
          .from('reservations')
          .select('''
            id, status, seats, pickup_point, passenger_profile_id, trip_id,
            profiles:passenger_profile_id(name, first_name, last_name)
          ''')
          .eq('id', reservaId)
          .maybeSingle();

      if (reserva == null) {
        setState(() => _resultado = 'QR invalido — reserva no encontrada');
        await _reactivarEscanner();
        return;
      }

      if (reserva['status']?.toString() != 'activa') {
        setState(() => _resultado = 'Esta reserva ya fue usada o cancelada');
        await _reactivarEscanner();
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _resultado = 'No hay una sesion activa');
        await _reactivarEscanner();
        return;
      }

      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('profile_id', user.id)
          .single();

      final trip = await Supabase.instance.client
          .from('trips')
          .select('id')
          .eq('driver_id', driver['id'])
          .inFilter('status', ['esperando', 'en_ruta'])
          .maybeSingle();

      if (trip == null || reserva['trip_id']?.toString() != trip['id']?.toString()) {
        setState(() => _resultado = 'Este pasajero no pertenece a tu viaje');
        await _reactivarEscanner();
        return;
      }

      final manifest = await Supabase.instance.client
          .from('manifests')
          .select('id')
          .eq('trip_id', trip['id'])
          .single();

      final passengerProfileId = reserva['passenger_profile_id']?.toString();
      if (passengerProfileId == null || passengerProfileId.isEmpty) {
        setState(() => _resultado = 'QR invalido');
        await _reactivarEscanner();
        return;
      }

      final existingEntries = await Supabase.instance.client
          .from('manifest_entries')
          .select('boarding_status')
          .eq('manifest_id', manifest['id'])
          .eq('passenger_profile_id', passengerProfileId);

      final alreadyBoarded = (existingEntries as List).any(
        (entry) => (entry as Map)['boarding_status']?.toString() == 'abordo',
      );

      if (alreadyBoarded) {
        setState(() => _resultado = 'Este pasajero ya abordo');
        await _reactivarEscanner();
        return;
      }

      await Supabase.instance.client
          .from('manifest_entries')
          .update({
            'boarding_status': 'abordo',
            'reservation_id': reservaId,
          })
          .eq('manifest_id', manifest['id'])
          .eq('passenger_profile_id', passengerProfileId);

      ref.invalidate(conductorManifiestoProvider);
      HapticFeedback.mediumImpact();

      final perfil = _asMap(reserva['profiles']);
      final nombre = _passengerName(perfil);
      final asientos = _parseSeats(reserva['seats']).map((s) => '#$s').join(', ');

      setState(() {
        _resultado =
            'Abordaje confirmado\n$nombre\nAsientos: ${asientos.isEmpty ? '—' : asientos}\nRecojo: ${reserva['pickup_point'] ?? '—'}';
      });

      await _reactivarEscanner(delay: const Duration(seconds: 3));
    } catch (e) {
      if (!mounted) return;
      setState(() => _resultado = 'Error: $e');
      await _reactivarEscanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: const Text('Escanear QR'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'No se pudo abrir la camara.\nConcede el permiso de camara en ajustes del telefono.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        error.errorDetails?.message ?? error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Oscurece bordes sin BlendMode.clear (evita pantalla negra en Android).
          IgnorePointer(
            child: CustomPaint(
              painter: _ScannerDimOverlayPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_resultado == null)
            const Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Text(
                'Apunta al QR del pasajero',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
            ),
          if (_resultado != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Text(
                    _resultado!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Oscurece el area fuera del marco sin usar BlendMode.clear.
class _ScannerDimOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const holeSize = 250.0;
    final holeLeft = (size.width - holeSize) / 2;
    final holeTop = (size.height - holeSize) / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(holeLeft, holeTop, holeSize, holeSize),
          const Radius.circular(12),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withAlpha(140),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

List<int> _parseSeats(dynamic rawSeats) {
  if (rawSeats is! List) return const [];
  final out = <int>[];
  for (final seat in rawSeats) {
    if (seat is int) out.add(seat);
    if (seat is num) out.add(seat.toInt());
    if (seat is String) {
      final parsed = int.tryParse(seat);
      if (parsed != null) out.add(parsed);
    }
  }
  out.sort();
  return out;
}

String _passengerName(Map<String, dynamic>? profile) {
  if (profile == null) return 'Pasajero';
  final name = profile['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final first = profile['first_name']?.toString().trim() ?? '';
  final last = profile['last_name']?.toString().trim() ?? '';
  final full = '$first $last'.trim();
  return full.isEmpty ? 'Pasajero' : full;
}
