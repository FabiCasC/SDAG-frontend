import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/history_search_bar.dart';
import '../widgets/time_filters_widget.dart';
import '../widgets/audit_log_tile.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _searchQuery = '';
  String _selectedFilter = 'Día';

  // Datos mockeados simulando la estructura en Firebase audit_logs
  final List<Map<String, dynamic>> _mockLogs = [
    {
      'id': 'log1',
      'plate': 'ABC-123',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'alert_accepted': true, // Excepción de seguridad (Bypass)
      'expired_documents': ['SOAT'],
      'action': 'manual_activation_bypass',
    },
    {
      'id': 'log2',
      'plate': 'DEF-456',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'alert_accepted': false,
      'expired_documents': [],
      'action': 'standard_activation',
    },
    {
      'id': 'log3',
      'plate': 'GHI-789',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'alert_accepted': true,
      'expired_documents': ['Licencia', 'SOAT'],
      'action': 'manual_activation_bypass',
    },
    {
      'id': 'log4',
      'plate': 'JKL-012',
      'timestamp': DateTime.now().subtract(const Duration(days: 8)),
      'alert_accepted': false,
      'expired_documents': [],
      'action': 'standard_activation',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Lógica de filtrado local combinando texto (placa) y el rango temporal
    final filteredLogs = _mockLogs.where((log) {
      final query = _searchQuery.toLowerCase();
      final matchesPlate = log['plate'].toString().toLowerCase().contains(query);

      final logDate = log['timestamp'] as DateTime;
      final now = DateTime.now();
      bool matchesTime = true;
      
      if (_selectedFilter == 'Día') {
        matchesTime = logDate.day == now.day && logDate.month == now.month && logDate.year == now.year;
      } else if (_selectedFilter == 'Semana') {
        final difference = now.difference(logDate).inDays;
        matchesTime = difference <= 7;
      } else if (_selectedFilter == 'Mes') {
        matchesTime = logDate.month == now.month && logDate.year == now.year;
      }

      return matchesPlate && matchesTime;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría y Logs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            HistorySearchBar(
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TimeFiltersWidget(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron registros para este periodo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return AuditLogTile(
                          plate: log['plate'],
                          date: log['timestamp'],
                          isBypass: log['alert_accepted'], // Valida si requiere el ícono de advertencia
                          expiredDocs: List<String>.from(log['expired_documents'] ?? []),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
