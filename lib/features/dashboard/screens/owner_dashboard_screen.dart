import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/screens/login_screen.dart';
import '../../pricing/screens/pricing_screen.dart';
import '../../staff/screens/staff_management_screen.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/custom_text_field.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final List<Map<String, dynamic>> _kpis = const [
    {'title': 'Unidades', 'value': '12', 'icon': Icons.directions_bus_filled_rounded},
    {'title': 'En carga', 'value': '5', 'icon': Icons.timelapse_rounded},
    {'title': 'Ingresos', 'value': 'S/ 1,240', 'icon': Icons.payments_rounded},
    {'title': 'Ocupación', 'value': '78%', 'icon': Icons.stacked_bar_chart_rounded},
  ];

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openFleetManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerFleetManagementScreen()),
    );
  }

  void _openStaffManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StaffManagementScreen()),
    );
  }

  void _openPricing() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PricingScreen()),
    );
  }

  void _openAudit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerAuditScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dueño'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.dashboard_rounded, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Control y métricas', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Accede a KPIs y a los módulos de gestión.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('KPIs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _kpis.map((kpi) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(kpi['icon'] as IconData, color: AppColors.primaryBlue),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              kpi['value'] as String,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kpi['title'] as String,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Gestión', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.directions_bus_filled_rounded,
              title: 'Gestionar vehículos',
              subtitle: 'Registro de placas y capacidades',
              onTap: _openFleetManagement,
            ),
            _NavCard(
              icon: Icons.groups_rounded,
              title: 'Gestionar staff',
              subtitle: 'Crear chofer y vincular a una placa',
              onTap: _openStaffManagement,
            ),
            _NavCard(
              icon: Icons.attach_money_rounded,
              title: 'Tarifario',
              subtitle: 'Definir precios por ruta',
              onTap: _openPricing,
            ),
            _NavCard(
              icon: Icons.verified_user_rounded,
              title: 'Auditoría',
              subtitle: 'Validar pagos de comisión en efectivo',
              onTap: _openAudit,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class OwnerFleetManagementScreen extends StatefulWidget {
  const OwnerFleetManagementScreen({super.key});

  @override
  State<OwnerFleetManagementScreen> createState() => _OwnerFleetManagementScreenState();
}

class _OwnerFleetManagementScreenState extends State<OwnerFleetManagementScreen> {
  final List<Map<String, dynamic>> _fleet = [
    {'placa': 'BJK-102', 'capacidad': 4, 'estado': 'Activo'},
    {'placa': 'XTR-990', 'capacidad': 15, 'estado': 'Mantenimiento'},
  ];

  void _showAddUnitBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _AddUnitForm(),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _fleet.add(result);
        });
        CustomSnackbar.show(
          context,
          message: 'Unidad registrada',
          isSuccess: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de activos'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _fleet.length,
        itemBuilder: (context, index) {
          final unit = _fleet[index];
          final status = unit['estado'] as String? ?? '-';
          final badgeColor = status == 'Activo' ? AppColors.success : AppColors.warning;

          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_bus_filled_rounded, color: AppColors.primaryBlue),
              ),
              title: Text(
                'Placa: ${unit['placa']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('Capacidad: ${unit['capacidad']} pax'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUnitBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddUnitForm extends StatefulWidget {
  const _AddUnitForm();

  @override
  State<_AddUnitForm> createState() => _AddUnitFormState();
}

class _AddUnitFormState extends State<_AddUnitForm> {
  final TextEditingController _placaController = TextEditingController();
  int _selectedCapacity = 4;
  final List<int> _capacities = [4, 6, 8, 15];

  void _saveUnit() {
    if (_placaController.text.trim().isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Ingrese una placa válida',
        isError: true,
      );
      return;
    }
    Navigator.pop(context, {
      'placa': _placaController.text.trim(),
      'capacidad': _selectedCapacity,
      'estado': 'Activo',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Añadir unidad',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Placa',
            hint: 'Ej: ABC-123',
            controller: _placaController,
          ),
          const SizedBox(height: 24),
          Text(
            'Capacidad (Pasajeros)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _capacities.map((cap) {
              final isSelected = _selectedCapacity == cap;
              return ChoiceChip(
                label: Text('$cap'),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCapacity = cap;
                  });
                },
                selectedColor: AppColors.primaryBlue.withOpacity(0.12),
                backgroundColor: AppColors.white,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Guardar',
            onPressed: _saveUnit,
          ),
        ],
      ),
    );
  }
}

class OwnerAuditScreen extends StatefulWidget {
  const OwnerAuditScreen({super.key});

  @override
  State<OwnerAuditScreen> createState() => _OwnerAuditScreenState();
}

class _OwnerAuditScreenState extends State<OwnerAuditScreen> {
  final List<Map<String, dynamic>> _pending = [
    {'chofer': 'Juan Pérez', 'placa': 'BJK-102', 'monto': 12.0, 'metodo': 'Efectivo'},
    {'chofer': 'Carlos Ruiz', 'placa': 'XTR-990', 'monto': 15.0, 'metodo': 'Efectivo'},
  ];

  void _approve(int index) {
    final item = _pending[index];
    setState(() {
      _pending.removeAt(index);
    });
    CustomSnackbar.show(
      context,
      message: 'Pago validado (${item['chofer']})',
      isSuccess: true,
    );
  }

  void _reject(int index) {
    final item = _pending[index];
    setState(() {
      _pending.removeAt(index);
    });
    CustomSnackbar.show(
      context,
      message: 'Pago observado (${item['chofer']})',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_pending.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hay pagos pendientes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ..._pending.asMap().entries.expand((e) {
              final index = e.key;
              final item = e.value;
              return [
                if (index > 0) const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.energeticOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.energeticOrange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['chofer']} • ${item['placa']}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Comisión: S/ ${item['monto']} • ${item['metodo']}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _reject(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.energeticOrange,
                                  foregroundColor: AppColors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Observar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _approve(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Validar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            }).toList(),
        ],
      ),
    );
  }
}
