import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';

class DriverMonitorCargaScreen extends StatefulWidget {
  const DriverMonitorCargaScreen({super.key});

  @override
  State<DriverMonitorCargaScreen> createState() => _DriverMonitorCargaScreenState();
}

class _DriverMonitorCargaScreenState extends State<DriverMonitorCargaScreen> {
  final int _capacity = 15;
  int _filled = 9;

  void _addPassenger() {
    if (_filled >= _capacity) return;
    setState(() {
      _filled += 1;
    });

    if (_filled >= _capacity) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Unidad completa'),
            content: const Text('La unidad llegó al 100% de ocupación.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _goToCommission() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DriverCommissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_filled / _capacity).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de carga'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ocupación', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pct >= 1 ? AppColors.energeticOrange : AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_filled/$_capacity',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pct >= 1 ? 'Listo para despacho' : 'Cargando pasajeros…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addPassenger,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Simular abordaje'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: pct >= 1 ? _goToCommission : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.energeticOrange,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Liquidar comisión'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverCommissionScreen extends StatefulWidget {
  const DriverCommissionScreen({super.key});

  @override
  State<DriverCommissionScreen> createState() => _DriverCommissionScreenState();
}

class _DriverCommissionScreenState extends State<DriverCommissionScreen> {
  bool _paid = false;

  void _payDigital() {
    setState(() {
      _paid = true;
    });
    CustomSnackbar.show(
      context,
      message: 'Comisión pagada (demo)',
      isSuccess: true,
    );
  }

  void _requestOnsite() {
    CustomSnackbar.show(
      context,
      message: 'Solicitud enviada a auditoría (demo)',
      isSuccess: true,
    );
  }

  void _openManifest() {
    if (!_paid) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DriverManifestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquidación de comisión'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (_paid ? AppColors.success : AppColors.warning).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _paid ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              color: _paid ? AppColors.success : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _paid ? 'Comisión pagada' : 'Pendiente de pago',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            'S/ 12.00',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: _paid ? 'Pago registrado' : 'Pagar digital',
                onPressed: _paid ? null : _payDigital,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _requestOnsite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.energeticOrange,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Solicitar validación presencial'),
              ),
              const Spacer(),
              CustomButton(
                text: 'Ver manifiesto',
                onPressed: _paid ? _openManifest : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverManifestScreen extends StatelessWidget {
  const DriverManifestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final passengers = const [
      {'dni': '70123456', 'destino': 'Chosica'},
      {'dni': '70999888', 'destino': 'Chosica'},
      {'dni': '71222333', 'destino': 'Chosica'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manifiesto electrónico'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoja de ruta', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Lima → Chosica',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lista de pasajeros',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...passengers.asMap().entries.expand((e) {
              final index = e.key;
              final p = e.value;
              return [
                if (index > 0) const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.primaryBlue),
                    ),
                    title: Text('DNI: ${p['dni']}'),
                    subtitle: Text('Destino: ${p['destino']}'),
                  ),
                ),
              ];
            }).toList(),
          ],
        ),
      ),
    );
  }
}
