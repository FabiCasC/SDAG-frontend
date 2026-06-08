import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primaryBlue = Color(0xFF2563EB);
  static const energeticOrange = Color(0xFFF97316);
  static const deepBlue = Color(0xFF1E40AF);

  static const white = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF314158);
  static const textSecondary = Color(0xFF62748E);

  static const border = Color(0xFFE2E8F0);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const fieldFill = Color(0xFFF1F5F9);

  static const darkSurface = Color(0xFF0B1220);
  static const darkOnSurface = Color(0xFFE5E7EB);

  static const shadow = Color(0x14000000);

  static const primaryTint08 = Color(0x142563EB);
  static const primaryTint12 = Color(0x1F2563EB);
  static const primaryTint18 = Color(0x2E2563EB);

  static const infoSurface = Color(0xFFDBEAFE);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);
  static const info = primaryBlue;

  static const seatOkBg = Color(0xFFDCFCE7);
  static const seatWarnBg = Color(0xFFFEF9C3);
  static const seatBadBg = Color(0xFFFEE2E2);
  static const ratingStar = Color(0xFFF59E0B);

  static ColorScheme lightScheme() {
    return const ColorScheme.light(
      primary: primaryBlue,
      secondary: energeticOrange,
      surface: white,
      error: error,
      onPrimary: white,
      onSecondary: white,
      onSurface: textPrimary,
      onError: white,
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme.dark(
      primary: primaryBlue,
      secondary: energeticOrange,
      surface: darkSurface,
      error: error,
      onPrimary: white,
      onSecondary: white,
      onSurface: darkOnSurface,
      onError: white,
    );
  }
}

