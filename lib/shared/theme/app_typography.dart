import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme lightTextTheme() => _base(AppColors.textPrimary);

  static TextTheme darkTextTheme() => _base(const Color(0xFFE5E7EB));

  static TextTheme _base(Color color) {
    final base = GoogleFonts.interTextTheme();

    TextStyle style({
      required double size,
      required FontWeight weight,
      required double lineHeightPx,
      Color? c,
    }) {
      return base.bodyMedium!.copyWith(
        fontSize: size,
        fontWeight: weight,
        height: lineHeightPx / size,
        color: c ?? color,
      );
    }

    return TextTheme(
      displaySmall: style(size: 30, weight: FontWeight.w700, lineHeightPx: 36),
      headlineSmall: style(size: 22, weight: FontWeight.w700, lineHeightPx: 28),
      titleLarge: style(size: 18, weight: FontWeight.w600, lineHeightPx: 24),
      titleMedium: style(size: 16, weight: FontWeight.w600, lineHeightPx: 22),
      bodyLarge: style(size: 14, weight: FontWeight.w400, lineHeightPx: 22),
      bodyMedium: style(size: 12, weight: FontWeight.w400, lineHeightPx: 18),
      bodySmall: style(size: 10, weight: FontWeight.w400, lineHeightPx: 14),
    );
  }
}
