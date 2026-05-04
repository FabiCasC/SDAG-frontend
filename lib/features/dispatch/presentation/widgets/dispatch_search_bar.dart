import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DispatchSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const DispatchSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Buscar conductor por placa...',
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
      ),
    );
  }
}
