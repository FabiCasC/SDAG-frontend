import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_manifiesto_provider.dart';

enum _ScanResultType { idle, success, error }

class ConductorQrScannerScreen extends ConsumerStatefulWidget {
  const ConductorQrScannerScreen({super.key});

  @override
  ConsumerState<ConductorQrScannerScreen> createState() => _ConductorQrScannerScreenState();
}

class _ConductorQrScannerScreenState extends ConsumerState<ConductorQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _processing = false;
  bool _scannerPaused = false;
  bool _cooldownFinished = true;
  Timer? _cooldownTimer;
  _ScanOutcome? _result;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pauseScannerForCooldown() async {
    _cooldownTimer?.cancel();
    _cooldownFinished = false;
    _scannerPaused = true;
    await _controller.stop();
    _cooldownTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _cooldownFinished = true;
      });
    });
  }

  Future<void> _resetScanner() async {
    if (!_cooldownFinished || _processing) return;
    setState(() {
      _result = null;
      _scannerPaused = false;
    });
    await _controller.start();
  }

  Future<void> _setErrorResult(String message) async {
    await _pauseScannerForCooldown();
    if (!mounted) return;
    setState(() {
      _result = _ScanOutcome.error(message: message);
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _scannerPaused || _result != null) return;
    final qrValue = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue?.trim() : null;
    if (qrValue == null || qrValue.isEmpty) return;

    _processing = true;
    try {
      final reserva = await Supabase.instance.client
          .from('reservations')
          .select('''
            id, status, seats, pickup_point, trip_id, passenger_profile_id,
            profiles:passenger_profile_id(name, first_name, last_name, dni, phone)
          ''')
          .eq('id', qrValue)
          .maybeSingle();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        await _setErrorResult('No hay una sesión activa');
        return;
      }

      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('profile_id', user.id)
          .single();

      final tripActivo = await Supabase.instance.client
          .from('trips')
          .select('id')
          .eq('driver_id', driver['id'])
          .inFilter('status', ['esperando', 'en_ruta'])
          .maybeSingle();

      if (reserva == null) {
        await _setErrorResult('QR inválido');
        return;
      }

      if (tripActivo == null) {
        await _setErrorResult('No tienes un viaje activo');
        return;
      }

      if (reserva['trip_id']?.toString() != tripActivo['id']?.toString()) {
        await _setErrorResult('Este pasajero no pertenece a tu viaje');
        return;
      }

      if (reserva['status']?.toString() != 'activa') {
        await _setErrorResult('Esta reserva ya fue usada o cancelada');
        return;
      }

      final manifest = await Supabase.instance.client
          .from('manifests')
          .select('id')
          .eq('trip_id', tripActivo['id'])
          .single();

      final passengerProfileId = reserva['passenger_profile_id']?.toString();
      if (passengerProfileId == null || passengerProfileId.isEmpty) {
        await _setErrorResult('QR inválido');
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
        await _setErrorResult('Este pasajero ya abordó');
        return;
      }

      await Supabase.instance.client
          .from('manifest_entries')
          .update({'boarding_status': 'abordo'})
          .eq('manifest_id', manifest['id'])
          .eq('passenger_profile_id', passengerProfileId);

      ref.invalidate(conductorManifiestoProvider);
      HapticFeedback.mediumImpact();

      final profile = _asMap(reserva['profiles']);
      final seats = _parseSeats(reserva['seats']);
      final outcome = _ScanOutcome.success(
        passengerName: _passengerName(profile),
        seatsLabel: seats.isEmpty ? '—' : seats.map((seat) => '#$seat').join(', '),
        pickupPoint: reserva['pickup_point']?.toString() ?? '—',
      );

      await _pauseScannerForCooldown();
      if (!mounted) return;
      setState(() {
        _result = outcome;
      });
    } catch (e) {
      await _setErrorResult('No se pudo validar el QR: $e');
    } finally {
      _processing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = switch (_result?.type) {
      _ScanResultType.success => const Color(0xFF16A34A),
      _ScanResultType.error => const Color(0xFFDC2626),
      _ => Colors.transparent,
    };

    final overlayIcon = switch (_result?.type) {
      _ScanResultType.success => Icons.check_circle_rounded,
      _ScanResultType.error => Icons.cancel_rounded,
      _ => null,
    };

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
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),
          if (overlayIcon != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: overlayColor.withAlpha(28),
                  child: Center(
                    child: Icon(
                      overlayIcon,
                      color: overlayColor,
                      size: 92,
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.p20),
                child: _result == null
                    ? const _ScannerInstructionsCard()
                    : _ScanResultCard(
                        result: _result!,
                        canScanNext: _cooldownFinished,
                        onScanNext: _resetScanner,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOutcome {
  const _ScanOutcome({
    required this.type,
    required this.message,
    this.passengerName,
    this.seatsLabel,
    this.pickupPoint,
  });

  const _ScanOutcome.success({
    required String passengerName,
    required String seatsLabel,
    required String pickupPoint,
  }) : this(
          type: _ScanResultType.success,
          message: 'Abordaje confirmado',
          passengerName: passengerName,
          seatsLabel: seatsLabel,
          pickupPoint: pickupPoint,
        );

  const _ScanOutcome.error({
    required String message,
  }) : this(
          type: _ScanResultType.error,
          message: message,
        );

  final _ScanResultType type;
  final String message;
  final String? passengerName;
  final String? seatsLabel;
  final String? pickupPoint;
}

class _ScannerInstructionsCard extends StatelessWidget {
  const _ScannerInstructionsCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Escanea el QR del pasajero',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'El sistema validará la reserva en Supabase y confirmará el abordaje solo si pertenece a tu viaje activo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({
    required this.result,
    required this.canScanNext,
    required this.onScanNext,
  });

  final _ScanOutcome result;
  final bool canScanNext;
  final Future<void> Function() onScanNext;

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.type == _ScanResultType.success;
    final color = isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: color, size: 88),
            const SizedBox(height: AppSpacing.md),
            if (result.passengerName != null)
              Text(
                result.passengerName!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            if (result.passengerName != null) const SizedBox(height: AppSpacing.sm),
            if (result.seatsLabel != null)
              Text(
                'Asientos: ${result.seatsLabel}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            if (result.pickupPoint != null) const SizedBox(height: AppSpacing.xs),
            if (result.pickupPoint != null)
              Text(
                result.pickupPoint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: canScanNext ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
              ),
              onPressed: canScanNext ? onScanNext : null,
              child: Text(canScanNext ? 'Escanear siguiente' : 'Espera 3 segundos...'),
            ),
          ],
        ),
      ),
    );
  }
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

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withAlpha(120);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    final rectSize = Size(min(size.width * 0.72, 320), min(size.width * 0.72, 320));
    final rectLeft = (size.width - rectSize.width) / 2;
    final rectTop = (size.height - rectSize.height) / 2.4;
    final rect = Rect.fromLTWH(rectLeft, rectTop, rectSize.width, rectSize.height);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      clearPaint,
    );

    final cornerPaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const corner = 26.0;
    final r = rect;
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + corner)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left + corner, r.top),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.right - corner, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.top + corner),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.bottom - corner)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.left + corner, r.bottom),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.right - corner, r.bottom)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.right, r.bottom - corner),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _initials(String first, String last) {
  final a = first.trim().isNotEmpty ? first.trim()[0].toUpperCase() : '';
  final b = last.trim().isNotEmpty ? last.trim()[0].toUpperCase() : '';
  final out = '$a$b';
  return out.isEmpty ? 'P' : out;
}
