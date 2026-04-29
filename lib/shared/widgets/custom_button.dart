import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isCritical;
  final bool isLoading;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isCritical = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isCritical ? AppColors.energeticOrange : AppColors.primaryBlue,
      ),
      child: isLoading
          ? const SizedBox(height: 24, width: 24, child: _BrandSpinner())
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
    );
  }
}

class _BrandSpinner extends StatefulWidget {
  const _BrandSpinner();

  @override
  State<_BrandSpinner> createState() => _BrandSpinnerState();
}

class _BrandSpinnerState extends State<_BrandSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Transform.rotate(
          angle: _c.value * 6.283185307179586,
          child: const Icon(Icons.directions_bus_filled_rounded, color: AppColors.white, size: 18),
        );
      },
    );
  }
}

class BrandLoadingPanel extends StatefulWidget {
  const BrandLoadingPanel({
    super.key,
    this.message = 'Cargando...',
    this.timeout = const Duration(seconds: 15),
    this.onRetry,
  });

  final String message;
  final Duration timeout;
  final VoidCallback? onRetry;

  @override
  State<BrandLoadingPanel> createState() => _BrandLoadingPanelState();
}

class _BrandLoadingPanelState extends State<BrandLoadingPanel> {
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.timeout, () {
      if (!mounted) return;
      setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        const SizedBox(height: 48, width: 48, child: _BrandSpinner()),
        const SizedBox(height: 12),
        Text(widget.message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        if (_timedOut) ...[
          const SizedBox(height: 12),
          if (widget.onRetry != null)
            CustomButton(
              text: 'Reintentar',
              onPressed: widget.onRetry,
            ),
        ],
      ],
    );
  }
}
