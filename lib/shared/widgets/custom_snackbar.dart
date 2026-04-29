import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    Color bgColor = AppColors.primaryBlue;
    if (isError) bgColor = AppColors.error;
    if (isSuccess) bgColor = AppColors.success;
    if (isWarning) bgColor = AppColors.warning;

    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(20),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
