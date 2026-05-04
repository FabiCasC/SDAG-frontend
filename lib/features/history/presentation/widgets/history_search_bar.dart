import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HistorySearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const HistorySearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Filtrar log por número de placa...',
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
      ),
    );
  }
}
