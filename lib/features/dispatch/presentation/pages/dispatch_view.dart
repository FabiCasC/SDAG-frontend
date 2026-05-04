import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/full_screen_alert_modal.dart';
import '../widgets/dispatch_search_bar.dart';
import '../widgets/driver_card_item.dart';
import '../../data/repositories/dispatch_repository.dart';

class DispatchView extends StatefulWidget {
  const DispatchView({super.key});

  @override
  State<DispatchView> createState() => _DispatchViewState();
}

class _DispatchViewState extends State<DispatchView> {
  final DispatchRepository _repository = DispatchRepository();
  String _searchQuery = '';

  // Datos mockeados simulando la lista de conductores
  final List<Map<String, dynamic>> _mockDrivers = [
    {
      'id': 'd1',
      'name': 'Juan Pérez Torres',
      'plate': 'ABC-123',
      'isOnline': false,
      'hasExpiredDocs': true,
      'expiredDocs': ['SOAT'],
    },
    {
      'id': 'd2',
      'name': 'María García R.',
      'plate': 'DEF-456',
      'isOnline': true,
      'hasExpiredDocs': false,
      'expiredDocs': [],
    },
    {
      'id': 'd3',
      'name': 'Carlos López M.',
      'plate': 'GHI-789',
      'isOnline': false,
      'hasExpiredDocs': true,
      'expiredDocs': ['SOAT', 'Licencia'],
    },
  ];

  void _handleActivate(Map<String, dynamic> driver) {
    if (driver['hasExpiredDocs']) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenAlertModal(
            driverName: driver['name'],
            plate: driver['plate'],
            expiredDocs: List<String>.from(driver['expiredDocs']),
            onCancel: () => Navigator.of(context).pop(),
            onContinue: () async {
              Navigator.of(context).pop();
              await _activateDriverBypass(driver);
            },
          ),
          fullscreenDialog: true,
        ),
      );
    } else {
      _activateDriverNormal(driver);
    }
  }

  Future<void> _activateDriverNormal(Map<String, dynamic> driver) async {
    try {
      await _repository.activateDriver(driver['id']);
      setState(() {
        driver['isOnline'] = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conductor activado correctamente'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      debugPrint("Error activando normal: $e");
    }
  }

  Future<void> _activateDriverBypass(Map<String, dynamic> driver) async {
    try {
      await _repository.activateDriver(driver['id']);
      await _repository.logAuditAlert(
        driverId: driver['id'],
        plate: driver['plate'],
        expiredDocs: List<String>.from(driver['expiredDocs']),
      );
      setState(() {
        driver['isOnline'] = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conductor activado con bypass legal'), backgroundColor: AppColors.energeticOrange),
        );
      }
    } catch (e) {
      debugPrint("Error activando bypass: $e");
    }
  }

  Future<void> _handleDeactivate(Map<String, dynamic> driver) async {
    try {
      await _repository.deactivateDriver(driver['id']);
      setState(() {
        driver['isOnline'] = false;
      });
    } catch (e) {
      debugPrint("Error desactivando: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDrivers = _mockDrivers.where((d) {
      final query = _searchQuery.toLowerCase();
      return d['plate'].toString().toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despacho en Vivo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            DispatchSearchBar(
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                itemCount: filteredDrivers.length,
                itemBuilder: (context, index) {
                  final driver = filteredDrivers[index];
                  return DriverCardItem(
                    name: driver['name'],
                    plate: driver['plate'],
                    isOnline: driver['isOnline'],
                    onActivate: () => _handleActivate(driver),
                    onDeactivate: () => _handleDeactivate(driver),
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
