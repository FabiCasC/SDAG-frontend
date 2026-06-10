import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import 'admin_vehiculos_screen.dart';

const _vehicleTypeOptions = <_VehicleTypeOption>[
  _VehicleTypeOption(label: 'Sedán/SUV', seats: 4),
  _VehicleTypeOption(label: 'SUV Grande', seats: 6),
  _VehicleTypeOption(label: 'Van', seats: 8),
  _VehicleTypeOption(label: 'Combi/Sprinter', seats: 14),
];

final adminVehiculoAssignableDriversProvider =
    FutureProvider<List<AdminVehiculoAssignableDriver>>((ref) async {
  final drivers = await Supabase.instance.client
      .from('drivers')
      .select('id, plate, profiles(name)')
      .eq('cuenta_activa', true);

  final vehicles = await Supabase.instance.client
      .from('vehicles')
      .select('driver_id')
      .not('driver_id', 'is', null);

  final assignedIds = (vehicles as List)
      .map((item) => (item as Map<String, dynamic>)['driver_id']?.toString())
      .whereType<String>()
      .toSet();

  return (drivers as List)
      .cast<Map<String, dynamic>>()
      .where((item) => !assignedIds.contains(item['id']?.toString()))
      .map(AdminVehiculoAssignableDriver.fromMap)
      .toList(growable: false);
});

class AdminVehiculoAssignableDriver {
  const AdminVehiculoAssignableDriver({
    required this.id,
    required this.nombre,
    required this.placaActual,
  });

  final String id;
  final String nombre;
  final String placaActual;

  factory AdminVehiculoAssignableDriver.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final name = profile?['name']?.toString().trim() ?? '';
    return AdminVehiculoAssignableDriver(
      id: map['id']?.toString() ?? '',
      nombre: name.isEmpty ? 'Conductor sin nombre' : name,
      placaActual: map['plate']?.toString() ?? '',
    );
  }
}

class AdminVehiculoCrearScreen extends ConsumerStatefulWidget {
  const AdminVehiculoCrearScreen({super.key});

  @override
  ConsumerState<AdminVehiculoCrearScreen> createState() => _AdminVehiculoCrearScreenState();
}

class _AdminVehiculoCrearScreenState extends ConsumerState<AdminVehiculoCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _placaController;
  late final TextEditingController _capacidadController;
  late final TextEditingController _colorController;
  late final TextEditingController _yearController;

  _VehicleTypeOption _selectedType = _vehicleTypeOptions[2];
  String? _selectedDriverId;
  bool _activo = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController();
    _capacidadController = TextEditingController(text: '${_selectedType.seats}');
    _colorController = TextEditingController();
    _yearController = TextEditingController();
  }

  @override
  void dispose() {
    _placaController.dispose();
    _capacidadController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;

    final plate = _placaController.text.trim().toUpperCase();
    final capacity = int.parse(_capacidadController.text.trim());
    final color = _colorController.text.trim();
    final year = int.tryParse(_yearController.text.trim());

    setState(() => _guardando = true);
    try {
      final vehicle = await Supabase.instance.client
          .from('vehicles')
          .insert({
            'plate': plate,
            'label': '${_selectedType.label} - $plate',
            'vehicle_type': _selectedType.label,
            'total_seats': capacity,
            'color': color.isEmpty ? null : color,
            'year': year,
            'active': _activo,
          })
          .select()
          .single();

      if (_selectedDriverId != null) {
        await Supabase.instance.client
            .from('vehicles')
            .update({'driver_id': _selectedDriverId})
            .eq('id', vehicle['id']);

        await Supabase.instance.client.from('drivers').update({
          'plate': plate,
          'vehicle_type': _selectedType.label,
          'capacity': capacity,
        }).eq('id', _selectedDriverId!);
      }

      if (!mounted) return;
      ref.invalidate(adminVehiculosProvider);
      ref.invalidate(adminVehiculoAssignableDriversProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Vehículo creado correctamente'),
        ),
      );
      context.go(AppRoutes.adminVehiculos);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('No se pudo crear el vehículo'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);
    final driversAsync = ref.watch(adminVehiculoAssignableDriversProvider);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        title: const Text('Nuevo vehículo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            _SectionCard(
              title: 'Datos del vehículo',
              child: Column(
                children: [
                  TextFormField(
                    controller: _placaController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      hintText: 'ABC-123',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La placa es obligatoria';
                      }
                      return RegExp(r'^[A-Z]{3}-\d{3}$').hasMatch(value.trim().toUpperCase())
                          ? null
                          : 'Usa el formato ABC-123';
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<_VehicleTypeOption>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo de vehículo'),
                    items: _vehicleTypeOptions
                        .map(
                          (item) => DropdownMenuItem<_VehicleTypeOption>(
                            value: item,
                            child: Text('${item.label} - ${item.seats} asientos'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedType = value;
                        _capacidadController.text = '${value.seats}';
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _capacidadController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Capacidad'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Color (opcional)'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Año (opcional)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final year = int.tryParse(value.trim());
                      if (year == null) return 'Ingresa un año válido';
                      if (year < 1900 || year > 2100) return 'Ingresa un año válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  driversAsync.when(
                    data: (drivers) => DropdownButtonFormField<String>(
                      initialValue: _selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Conductor asignado',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Sin asignar'),
                        ),
                        ...drivers.map(
                          (driver) => DropdownMenuItem<String>(
                            value: driver.id,
                            child: Text(driver.nombre),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _selectedDriverId = value),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) => const Text('No se pudieron cargar los conductores'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activo'),
                    value: _activo,
                    onChanged: (value) => setState(() => _activo = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
              ),
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Guardar vehículo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTypeOption {
  const _VehicleTypeOption({
    required this.label,
    required this.seats,
  });

  final String label;
  final int seats;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.shadowBlur,
            offset: Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
