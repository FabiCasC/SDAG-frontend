import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_manifiesto_provider.dart';
import '../providers/conductor_viaje_provider.dart';

enum _OverlayState { idle, ok, error }

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

  _OverlayState _overlay = _OverlayState.idle;
  Timer? _overlayTimer;
  bool _processing = false;
  ManifiestoItem? _current;

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setOverlay(_OverlayState state) {
    _overlayTimer?.cancel();
    setState(() => _overlay = state);
    if (state == _OverlayState.idle) return;
    _overlayTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _overlay = _OverlayState.idle);
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (raw == null || raw.trim().isEmpty) return;
    _processing = true;
    try {
      final parsed = _parseQr(raw);
      final manifiesto = ref.read(conductorManifiestoProvider).listaPasajeros;

      ManifiestoItem? passenger;
      if (parsed.passengerId != null) {
        passenger = manifiesto.where((p) => p.id == parsed.passengerId).cast<ManifiestoItem?>().firstWhere(
              (p) => p != null,
              orElse: () => null,
            );
      }
      passenger ??= manifiesto.where((p) => p.asiento == parsed.seat).cast<ManifiestoItem?>().firstWhere(
            (p) => p != null,
            orElse: () => null,
          );

      if (passenger == null || parsed.seat == null) {
        _setOverlay(_OverlayState.error);
        if (!mounted) return;
        AppSnackbars.error(context, 'QR inválido o ya utilizado');
        return;
      }

      if (passenger.estado == ManifiestoEstadoPasajero.subio) {
        if (!mounted) return;
        AppSnackbars.warning(context, 'Este pasajero ya abordó');
        return;
      }

      if (passenger.estado == ManifiestoEstadoPasajero.noSubio) {
        _setOverlay(_OverlayState.error);
        if (!mounted) return;
        AppSnackbars.error(context, 'QR inválido o ya utilizado');
        return;
      }

      HapticFeedback.mediumImpact();
      _setOverlay(_OverlayState.ok);
      if (!mounted) return;
      setState(() => _current = passenger);
    } finally {
      _processing = false;
    }
  }

  Future<void> _confirmBoarding(ManifiestoItem p) async {
    await ref.read(conductorManifiestoProvider.notifier).marcarAbordaje(p.id);
    ref.read(conductorViajeProvider.notifier).actualizarEstadoPasajero(
          pasajeroId: p.id,
          estado: EstadoPasajero.abordo,
        );
    if (!mounted) return;
    AppSnackbars.success(context, '${p.nombreCompleto} abordó');
    setState(() => _current = null);
  }

  Future<void> _markAbsent(ManifiestoItem p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Marcar como no abordó'),
          content: Text(
            '¿Confirmas que ${p.nombreCompleto} no abordó?\nSu pago NO será reembolsado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    await ref.read(conductorManifiestoProvider.notifier).marcarAusencia(p.id);
    ref.read(conductorViajeProvider.notifier).actualizarEstadoPasajero(
          pasajeroId: p.id,
          estado: EstadoPasajero.noAbordo,
        );

    if (!mounted) return;
    final viaje = ref.read(conductorViajeProvider);
    final canRevert = viaje.estadoViaje != ConductorEstadoViaje.enRuta;
    final snack = SnackBar(
      backgroundColor: AppColors.warning,
      content: const Text(
        'Ausencia registrada',
        style: TextStyle(color: AppColors.white),
      ),
      action: !canRevert
          ? null
          : SnackBarAction(
              label: 'Revertir',
              textColor: AppColors.white,
              onPressed: () async {
                await ref.read(conductorManifiestoProvider.notifier).revertirAusencia(p.id);
                ref.read(conductorViajeProvider.notifier).actualizarEstadoPasajero(
                      pasajeroId: p.id,
                      estado: EstadoPasajero.pendiente,
                    );
              },
            ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
    setState(() => _current = null);
  }

  @override
  Widget build(BuildContext context) {
    final manifiesto = ref.watch(conductorManifiestoProvider).listaPasajeros;
    final pendientes = manifiesto.where((p) => p.estado == ManifiestoEstadoPasajero.pendiente).toList()
      ..sort((a, b) => a.asiento.compareTo(b.asiento));

    final overlayColor = switch (_overlay) {
      _OverlayState.ok => const Color(0xFF16A34A),
      _OverlayState.error => const Color(0xFFDC2626),
      _OverlayState.idle => Colors.transparent,
    };

    final overlayIcon = switch (_overlay) {
      _OverlayState.ok => Icons.check_circle_rounded,
      _OverlayState.error => Icons.cancel_rounded,
      _OverlayState.idle => null,
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
                child: _current == null
                    ? _PendingListCard(
                        pendientes: pendientes,
                        onMarkAbsent: (p) => _markAbsent(p),
                      )
                    : _ScannedPassengerCard(
                        passenger: _current!,
                        onConfirm: () => _confirmBoarding(_current!),
                        onAbsent: () => _markAbsent(_current!),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedQr {
  const _ParsedQr({required this.passengerId, required this.seat});

  final String? passengerId;
  final int? seat;
}

_ParsedQr _parseQr(String raw) {
  final parts = raw.trim().split('|');
  if (parts.length >= 3) {
    final passengerId = parts[1].trim().isEmpty ? null : parts[1].trim();
    final seat = int.tryParse(parts[2].trim());
    return _ParsedQr(passengerId: passengerId, seat: seat);
  }
  return const _ParsedQr(passengerId: null, seat: null);
}

class _ScannedPassengerCard extends StatelessWidget {
  const _ScannedPassengerCard({
    required this.passenger,
    required this.onConfirm,
    required this.onAbsent,
  });

  final ManifiestoItem passenger;
  final VoidCallback onConfirm;
  final VoidCallback onAbsent;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(passenger.nombres, passenger.apellidos);
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
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryTint12,
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.nombreCompleto,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'DNI ${passenger.dni} · Asiento #${passenger.asiento}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              passenger.puntoRecojo,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
              ),
              onPressed: onConfirm,
              child: const Text('Confirmar abordaje'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
              ),
              onPressed: onAbsent,
              child: const Text('Marcar como no abordó'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingListCard extends StatelessWidget {
  const _PendingListCard({required this.pendientes, required this.onMarkAbsent});

  final List<ManifiestoItem> pendientes;
  final ValueChanged<ManifiestoItem> onMarkAbsent;

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
              'Pendientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (pendientes.isEmpty)
              Text(
                'No hay pasajeros pendientes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              )
            else
              ...pendientes.take(4).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p.nombreCompleto} · #${p.asiento}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => onMarkAbsent(p),
                            child: const Text('No abordó'),
                          ),
                        ],
                      ),
                    ),
                  ),
            if (pendientes.length > 4)
              Text(
                'y ${pendientes.length - 4} más…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
