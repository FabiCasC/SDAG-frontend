import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.showAppBar = true,
    this.padding,
    this.backgroundColor,
    this.bottomNavigationBar,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showAppBar;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: padding ?? AppSpacing.screenPadding,
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({
    this.showSlogan = true,
    this.center = true,
    super.key,
  });

  final bool showSlogan;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Center(
          child: _BrandMark(
            circleSize: AppSpacing.logoCircleSize,
            iconSize: AppSpacing.logoIconSize,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'SDAG',
          style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.deepBlue),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        if (showSlogan) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tu viaje, conectado',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: center ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.circleSize,
    required this.iconSize,
  });

  final double circleSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: AppColors.primaryTint08,
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          Icons.directions_bus_filled,
          size: iconSize,
          color: AppColors.primaryBlue,
        ),
        Positioned(
          left: circleSize * 0.18,
          child: Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: const BoxDecoration(
              color: AppColors.energeticOrange,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class AppAuthCard extends StatelessWidget {
  const AppAuthCard({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppSpacing.maxFormWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: SingleChildScrollView(
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppFormErrorText extends StatelessWidget {
  const AppFormErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;

    final child = loading
        ? const SizedBox(
            width: AppSpacing.lg,
            height: AppSpacing.lg,
            child: CircularProgressIndicator(strokeWidth: AppSpacing.progressStrokeWidth),
          )
        : Text(label);

    if (icon == null) {
      return FilledButton(
        onPressed: effectiveOnPressed,
        child: child,
      );
    }

    return FilledButton.icon(
      onPressed: effectiveOnPressed,
      icon: Icon(icon),
      label: child,
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class AppCriticalButton extends StatelessWidget {
  const AppCriticalButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: AppColors.energeticOrange,
      foregroundColor: AppColors.white,
      minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
    );

    if (icon == null) {
      return FilledButton(
        style: style,
        onPressed: onPressed,
        child: Text(label),
      );
    }

    return FilledButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.shadowBlur,
            offset: Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(color: AppColors.textSecondary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

enum AppStatusChipType {
  available,
  onRoute,
  full,
  pending,
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({required this.type, required this.label, super.key});

  final AppStatusChipType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      AppStatusChipType.available => (AppColors.success, AppColors.white),
      AppStatusChipType.onRoute => (AppColors.info, AppColors.white),
      AppStatusChipType.full => (AppColors.error, AppColors.white),
      AppStatusChipType.pending => (AppColors.warning, AppColors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg),
      ),
    );
  }
}

class AppSnackbars {
  AppSnackbars._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.info);

  static void warning(BuildContext context, String message) =>
      _show(context, message, AppColors.warning);

  static void _show(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      backgroundColor: color,
      content: Text(
        message,
        style: const TextStyle(color: AppColors.white),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

enum SeatState {
  available,
  occupied,
  selected,
}

class SeatMapWidget extends StatelessWidget {
  const SeatMapWidget({
    required this.seatCount,
    required this.occupiedSeats,
    required this.selectedSeats,
    required this.onSeatTap,
    super.key,
  });

  final int seatCount;
  final Set<int> occupiedSeats;
  final Set<int> selectedSeats;
  final ValueChanged<int> onSeatTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List<Widget>.generate(seatCount, (index) {
        final seatNumber = index + 1;
        final state = occupiedSeats.contains(seatNumber)
            ? SeatState.occupied
            : (selectedSeats.contains(seatNumber)
                ? SeatState.selected
                : SeatState.available);
        return _SeatTile(
          seatNumber: seatNumber,
          state: state,
          onTap: () => onSeatTap(seatNumber),
        );
      }),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.seatNumber,
    required this.state,
    required this.onTap,
  });

  final int seatNumber;
  final SeatState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, enabled) = switch (state) {
      SeatState.available => (AppColors.white, AppColors.textPrimary, true),
      SeatState.occupied => (AppColors.error, AppColors.white, false),
      SeatState.selected => (AppColors.primaryBlue, AppColors.white, true),
    };

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Ink(
        width: AppSpacing.seatSize,
        height: AppSpacing.seatSize,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            '$seatNumber',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: fg,
                ),
          ),
        ),
      ),
    );
  }
}
