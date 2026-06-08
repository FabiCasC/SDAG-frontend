import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = AppColors.lightScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: AppTypography.lightTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryBlue),
      dividerColor: AppColors.border,
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        constraints: const BoxConstraints(minHeight: AppSpacing.controlHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: TextStyle(color: AppColors.textSecondary),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: AppSpacing.focusBorderWidth,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          textStyle: AppTypography.lightTextTheme().titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          side: const BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          textStyle: AppTypography.lightTextTheme().titleMedium,
          foregroundColor: AppColors.primaryBlue,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: AppTypography.lightTextTheme().titleMedium,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryTint12,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.lightTextTheme().bodySmall,
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(size: 24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTypography.lightTextTheme()
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: AppTypography.lightTextTheme()
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: const <ThemeExtension<dynamic>>[],
    );
  }

  static ThemeData dark() {
    final scheme = AppColors.darkScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: AppTypography.darkTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        constraints: const BoxConstraints(minHeight: AppSpacing.controlHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: AppSpacing.focusBorderWidth,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          textStyle: AppTypography.darkTextTheme().titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          side: const BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          textStyle: AppTypography.darkTextTheme().titleMedium,
          foregroundColor: AppColors.primaryBlue,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: AppTypography.darkTextTheme().titleMedium,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.primaryTint18,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.darkTextTheme().bodySmall,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTypography.darkTextTheme()
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: AppTypography.darkTextTheme()
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static EdgeInsetsGeometry screenPadding() => AppSpacing.screenPadding;
}
