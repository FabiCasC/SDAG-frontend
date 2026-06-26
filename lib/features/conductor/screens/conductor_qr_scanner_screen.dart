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
import '../utils/qr_scan_utils.dart';

class ConductorQrScannerScreen extends ConsumerStatefulWidget {
  const ConductorQrScannerScreen({super.key});

  @override
  ConsumerState<ConductorQrScannerScreen> createState() => _ConductorQrScannerScreenState();
}

class _ConductorQrScannerScreenState extends ConsumerState<ConductorQrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.qrCode],
    returnImage: false,
  );

  static final _uuidRegex = reservationUuidRegex;

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

  void _onDetect(BarcodeCapture capture) {
    debugPrint('[QR] onDetect llamado — barcodes encontrados: ${capture.barcodes.length}');
    for (final b in capture.barcodes) {
      debugPrint('[QR] rawValue: ${b.rawValue} | format: ${b.format}');
    }
    if (!_escaneando) {
      debugPrint('[QR] ignorado — _escaneando=false');
      return;
    }
    if (_procesando) {
      debugPrint('[QR] ignorado — _procesando=true');
      return;
    }
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    if (barcode?.rawValue == null) {
      debugPrint('[QR] barcode sin rawValue, ignorado');
      return;
    }
    final raw = barcode!.rawValue!.trim();
    if (raw.isEmpty) {
      debugPrint('[QR] rawValue vacío, ignorado');
      return;
    }
    debugPrint('[QR] procesando reservaId=$raw');
    setState(() {
      _escaneando = false;
      _procesando = true;
    });
    unawaited(_procesarQR(raw));
  }

  Future<void> _procesarQR(String qrValue) async {
    final payload = parseQrScanValue(qrValue);
    final reservaId = payload.reservaId;
    final asientoNumero = payload.seatNumber;

    if (!isValidReservationUuid(reservaId)) {
      setState(() => _resultado = 'QR invalido');
      await _reactivarEscanner();
      return;
    }

    try {
      final reserva = await Supabase.instance.client
          .from('reservations')
          .select('''
            id, status, seats, pickup_point, passenger_profile_id, trip_id,
            profiles:passenger_profile_id(name, first_name, last_name, dni, phone)
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

        if (asientoNumero != null) {
        final reservedSeats = _parseSeats(reserva['seats']);
        if (!isSeatInReservation(asientoNumero, reservedSeats)) {
          setState(() => _resultado = 'Asiento no pertenece a esta reserva');
          await _reactivarEscanner();
          return;
        }

        final existingSeat = await Supabase.instance.client
            .from('manifest_entries')
            .select('id, boarding_status')
            .eq('reservation_id', reservaId)
            .eq('seat_number', asientoNumero)
            .maybeSingle();

        if (existingSeat?['boarding_status']?.toString() == 'abordo') {
          setState(() => _resultado = 'Este asiento ya fue escaneado');
          await _reactivarEscanner();
          return;
        }
      } else {
        final existingForReserva = await Supabase.instance.client
            .from('manifest_entries')
            .select('id, boarding_status')
            .eq('reservation_id', reservaId);

        final allBoarded = (existingForReserva as List).isNotEmpty &&
            (existingForReserva as List).every((entry) {
              final map = (entry as Map).cast<String, dynamic>();
              return map['boarding_status']?.toString() == 'abordo';
            });

        if (allBoarded) {
          setState(() => _resultado = 'Esta reserva ya fue escaneada');
          await _reactivarEscanner();
          return;
        }
      }

      final manifest = await Supabase.instance.client
          .from('manifests')
          .select('id')
          .eq('trip_id', trip['id'])
          .maybeSingle();

      late final String manifestId;
      if (manifest == null) {
        final newManifest = await Supabase.instance.client
            .from('manifests')
            .insert({'trip_id': trip['id'], 'estado': 'en_curso'})
            .select('id')
            .single();
        manifestId = newManifest['id'].toString();
      } else {
        manifestId = manifest['id'].toString();
      }

      List<dynamic> updateResult;
      if (asientoNumero != null) {
        updateResult = await Supabase.instance.client
            .from('manifest_entries')
            .update({'boarding_status': 'abordo'})
            .eq('manifest_id', manifestId)
            .eq('reservation_id', reservaId)
            .eq('seat_number', asientoNumero)
            .select();
      } else {
        updateResult = await Supabase.instance.client
            .from('manifest_entries')
            .update({'boarding_status': 'abordo'})
            .eq('manifest_id', manifestId)
            .eq('passenger_profile_id', reserva['passenger_profile_id'])
            .select();
      }

      debugPrint('[QR Scan] filas actualizadas: ${updateResult.length}');

      if (updateResult.isEmpty) {
        final perfilInsert = _asMap(reserva['profiles']);
        final seatsToInsert = asientoNumero != null
            ? [asientoNumero]
            : _parseSeats(reserva['seats']);

        for (final seat in seatsToInsert) {
          await Supabase.instance.client.from('manifest_entries').insert({
            'manifest_id': manifestId,
            'passenger_profile_id': reserva['passenger_profile_id'],
            'reservation_id': reserva['id'],
            'first_name': perfilInsert?['first_name'] ?? 'Sin nombre',
            'last_name': perfilInsert?['last_name'] ?? '',
            'dni': perfilInsert?['dni'] ?? 'Sin DNI',
            'phone': perfilInsert?['phone'] ?? 'Sin teléfono',
            'seat_number': seat,
            'pickup_text': reserva['pickup_point'] ?? 'Sin punto de recojo',
            'boarding_status': 'abordo',
          });
        }
      }

      ref.invalidate(conductorManifiestoProvider);
      HapticFeedback.mediumImpact();

      final perfil = _asMap(reserva['profiles']);
      final nombre = _passengerName(perfil);
      final asientoTexto = asientoNumero != null
          ? 'Asiento #$asientoNumero'
          : 'Todos los asientos';

      if (mounted) {
        setState(() {
          _resultado = 'Abordaje confirmado\n$nombre\n$asientoTexto';
        });
      }
      unawaited(_reactivarEscanner(delay: const Duration(seconds: 3)));
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
