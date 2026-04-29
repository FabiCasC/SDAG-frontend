import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_snackbar.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final List<Map<String, dynamic>> _staff = [
    {'name': 'Juan Pérez', 'placa': 'BJK-102'},
    {'name': 'Carlos Ruiz', 'placa': 'No asignada'},
  ];

  void _showAddDriverBottomSheet(BuildContext context) {
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
        child: const _AddDriverForm(),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _staff.add(result);
        });
        CustomSnackbar.show(
          context,
          message: 'Conductor vinculado exitosamente',
          isSuccess: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Staff'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _staff.length,
        itemBuilder: (context, index) {
          final driver = _staff[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.surfaceGrey,
                child: const Icon(Icons.person, color: AppColors.textSecondary, size: 30),
              ),
              title: Text(
                driver['name'],
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Placa vinculada: ${driver['placa']}',
                style: TextStyle(
                  color: driver['placa'] == 'No asignada' 
                      ? AppColors.warning 
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'owner_staff_management_fab',
        onPressed: () => _showAddDriverBottomSheet(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _AddDriverForm extends StatefulWidget {
  const _AddDriverForm({Key? key}) : super(key: key);

  @override
  State<_AddDriverForm> createState() => _AddDriverFormState();
}

class _AddDriverFormState extends State<_AddDriverForm> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _selectedPlaca;
  final List<String> _availablePlacas = ['BJK-102', 'XTR-990', 'ABC-123'];

  void _saveDriver() {
    if (_dniController.text.length != 8 || _nameController.text.isEmpty || _selectedPlaca == null) {
      CustomSnackbar.show(
        context,
        message: 'Por favor complete correctamente los campos',
        isError: true,
      );
      return;
    }
    
    Navigator.pop(context, {
      'name': _nameController.text,
      'placa': _selectedPlaca!,
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
            'Alta de Conductor',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'DNI (8 dígitos)',
            hint: 'Ej: 12345678',
            keyboardType: TextInputType.number,
            controller: _dniController,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Nombre Completo',
            hint: 'Ej: Juan Pérez',
            controller: _nameController,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Teléfono',
            hint: 'Ej: 999888777',
            keyboardType: TextInputType.phone,
            controller: _phoneController,
          ),
          const SizedBox(height: 16),
          Text(
            'Asignar Unidad',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPlaca,
                hint: const Text('Seleccionar Placa'),
                isExpanded: true,
                items: _availablePlacas.map((placa) {
                  return DropdownMenuItem(
                    value: placa,
                    child: Text(placa),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlaca = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Vincular Conductor',
            onPressed: _saveDriver,
          ),
        ],
      ),
    );
  }
}
