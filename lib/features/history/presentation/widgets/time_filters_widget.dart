import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TimeFiltersWidget extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const TimeFiltersWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['Día', 'Semana', 'Mes'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: filters.map((filter) {
        final isSelected = filter == selectedFilter;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) onFilterChanged(filter);
            },
            selectedColor: AppColors.primaryBlue.withOpacity(0.1),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primaryBlue : AppColors.surfaceGrey,
            ),
            backgroundColor: AppColors.white,
          ),
        );
      }).toList(),
    );
  }
}
