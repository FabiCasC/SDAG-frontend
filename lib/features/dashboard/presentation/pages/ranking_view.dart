import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../history/presentation/widgets/time_filters_widget.dart';
import '../widgets/ranking_list_item.dart';

class RankingView extends StatefulWidget {
  const RankingView({super.key});

  @override
  State<RankingView> createState() => _RankingViewState();
}

class _RankingViewState extends State<RankingView> {
  String _selectedFilter = 'Semana';

  // Datos mockeados de activaciones de conductores para demostrar la funcionalidad de RF 90
  final List<Map<String, dynamic>> _mockDriversData = [
    {'name': 'Juan Pérez Torres', 'plate': 'ABC-123', 'día': 5, 'semana': 32, 'mes': 120},
    {'name': 'María García R.', 'plate': 'DEF-456', 'día': 4, 'semana': 28, 'mes': 110},
    {'name': 'Carlos López M.', 'plate': 'GHI-789', 'día': 7, 'semana': 41, 'mes': 150},
    {'name': 'Ana Silva', 'plate': 'JKL-012', 'día': 2, 'semana': 15, 'mes': 85},
    {'name': 'Luis Martínez', 'plate': 'MNO-345', 'día': 6, 'semana': 38, 'mes': 130},
  ];

  @override
  Widget build(BuildContext context) {
    String filterKey = _selectedFilter.toLowerCase();
    
    // Clonar lista y ordenar descendentemente según la temporalidad
    List<Map<String, dynamic>> sortedData = List.from(_mockDriversData);
    sortedData.sort((a, b) => (b[filterKey] as int).compareTo(a[filterKey] as int));

    // Determinar el valor máximo para calcular la barra de progreso (0 a 1)
    int maxActivations = sortedData.isNotEmpty ? sortedData.first[filterKey] as int : 1;
    if (maxActivations == 0) maxActivations = 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Conductores'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Reutilización del selector temporal de Historial
            TimeFiltersWidget(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Resumen de estado (Dashboard)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Activos', '${sortedData.length}'),
                  _buildStatColumn('Viajes', '${sortedData.fold<int>(0, (sum, item) => sum + (item[filterKey] as int))}'),
                  _buildStatColumn('Promedio', '${(sortedData.fold<int>(0, (sum, item) => sum + (item[filterKey] as int)) / (sortedData.isEmpty ? 1 : sortedData.length)).toStringAsFixed(1)}'),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Top Productividad',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            Expanded(
              child: ListView.builder(
                itemCount: sortedData.length,
                itemBuilder: (context, index) {
                  final driver = sortedData[index];
                  final activations = driver[filterKey] as int;
                  final percentage = activations / maxActivations;
                  
                  return RankingListItem(
                    rank: index + 1,
                    driverName: driver['name'],
                    plate: driver['plate'],
                    activations: activations,
                    percentage: percentage,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.deepBlue, // Énfasis en Deep Blue
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
