import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_navigation_back.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/admin_conductores_provider.dart';
import 'admin_vehiculo_crear_screen.dart';
import 'admin_vehiculos_screen.dart';

extension _PostgrestIsFilter on PostgrestFilterBuilder {
  PostgrestFilterBuilder is_(String column, Object? value) => filter(column, 'is', value);
}

final adminAvailableVehiclesProvider = FutureProvider<List<AdminAvailableVehicle>>((ref) async {
  final List response = await Supabase.instance.client
      .from('vehicles')
      .select('id, plate, vehicle_type, total_seats')
      .is_('driver_id', null)
      .eq('active', true)
      .order('plate');

  debugPrint('[Vehiculos] disponibles: ${response.length} - $response');

  return response
      .cast<Map<String, dynamic>>()
      .map(AdminAvailableVehicle.fromMap)
      .toList(growable: false);
});

String? _previewToken(Session? session) {
  if (session == null) return null;
  final token = session.accessToken;
  final end = token.length < 20 ? token.length : 20;
  return token.substring(0, end);
}

class AdminAvailableVehicle {
  const AdminAvailableVehicle({
    required this.id,
    required this.plate,
    required this.vehicleType,
    required this.capacity,
  });

  final String id;
  final String plate;
  final String vehicleType;
  final int capacity;

  factory AdminAvailableVehicle.fromMap(Map<String, dynamic> map) {
    return AdminAvailableVehicle(
      id: map['id']?.toString() ?? '',
      plate: map['plate']?.toString() ?? '',
      vehicleType: map['vehicle_type']?.toString() ?? '',
      capacity: (map['total_seats'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminConductorCrearScreen extends ConsumerStatefulWidget {
  const AdminConductorCrearScreen({super.key});

  @override
  ConsumerState<AdminConductorCrearScreen> createState() => _AdminConductorCrearScreenState();
}

class _AdminConductorCrearScreenState extends ConsumerState<AdminConductorCrearScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _dniController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _guardando = false;
  bool _ocultarPassword = true;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _dniController = TextEditingController();
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio';
    return null;
  }

  String _functionErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('Failed to fetch') || text.contains('ClientException')) {
      return 'No se pudo crear el usuario. Verifica la conexión.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  Future<void> _guardar(List<AdminAvailableVehicle> vehicles) async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null || _selectedVehicleId!.isEmpty) {
      AppSnackbars.error(context, 'Selecciona un vehículo disponible');
      return;
    }

    final selectedVehicle = vehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;
    if (selectedVehicle == null) {
      AppSnackbars.error(context, 'El vehículo seleccionado ya no está disponible');
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final firstName = _nombreController.text.trim();
    final lastName = _apellidoController.text.trim();
    final dni = _dniController.text.trim();
    final phone = _telefonoController.text.trim();
    final session = Supabase.instance.client.auth.currentSession;

    if (!RegExp(r'^\d{9}$').hasMatch(phone)) {
      AppSnackbars.error(context, 'El teléfono debe tener 9 dígitos');
      return;
    }
    if (!RegExp(r'^\d{8}$').hasMatch(dni)) {
      AppSnackbars.error(context, 'El DNI debe tener 8 dígitos');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      AppSnackbars.error(context, 'Ingresa un email válido');
      return;
    }
    if (password.length < 8) {
      AppSnackbars.error(context, 'La contraseña debe tener al menos 8 caracteres');
      return;
    }
    if (selectedVehicle.plate.trim().isEmpty) {
      AppSnackbars.error(context, 'La placa no puede estar vacía');
      return;
    }

    setState(() => _guardando = true);
    try {
      debugPrint('[AdminCrearConductor] session: ${_previewToken(session)}');
      debugPrint('[AdminCrearConductor] user: ${Supabase.instance.client.auth.currentUser?.email}');

      final response = await Supabase.instance.client.functions.invoke(
        'create-driver',
        body: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'dni': dni,
          'phone': phone,
          'plate': selectedVehicle.plate,
          'vehicle_type': selectedVehicle.vehicleType,
          'capacity': selectedVehicle.capacity,
          'commission_pct': 15,
        },
      );

      debugPrint('[AdminCrearConductor] response status: ${response.status}');
      debugPrint('[AdminCrearConductor] response data: ${response.data}');

      if (!mounted) return;

      if (response.status >= 400) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error']?.toString()
            : data?.toString();
        throw Exception(message ?? 'No se pudo crear el usuario. Verifica la conexión.');
      }

      final data = response.data;
      final profileId = data is Map<String, dynamic> ? data['user_id']?.toString() : null;
      final newDriverId = data is Map<String, dynamic> ? data['driver_id']?.toString() : null;

      if (newDriverId != null && newDriverId.isNotEmpty) {
        await Supabase.instance.client
            .from('vehicles')
            .update({'driver_id': newDriverId})
            .eq('id', selectedVehicle.id);

        await Supabase.instance.client.from('drivers').update({
          'plate': selectedVehicle.plate,
          'vehicle_type': selectedVehicle.vehicleType,
          'capacity': selectedVehicle.capacity,
        }).eq('id', newDriverId);
      }

      ref.invalidate(adminAvailableVehiclesProvider);
      ref.invalidate(adminVehiculosProvider);
      ref.invalidate(adminVehiculoAssignableDriversProvider);
      await ref.read(adminConductoresProvider.notifier).refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Conductor registrado correctamente.'),
        ),
      );

      if (profileId != null && profileId.isNotEmpty) {
        context.go('/admin/conductores/$profileId');
      } else {
        context.go(AppRoutes.adminConductores);
      }
    } on FunctionException catch (e) {
      final details = e.details?.toString() ?? '';
      String mensaje = 'No se pudo crear el conductor.';

      if (details.contains('profiles_phone_key')) {
        mensaje = 'El número de teléfono ya está registrado.';
      } else if (details.contains('profiles_dni_key')) {
        mensaje = 'El DNI ya está registrado.';
      } else if (details.contains('profiles_email_key')) {
        mensaje = 'El correo electrónico ya está registrado.';
      } else if (details.contains('drivers_plate_key') || details.contains('vehicles_plate_key')) {
        mensaje = 'La placa ya está registrada.';
      } else if (details.contains('duplicate key')) {
        mensaje = 'Ya existe un registro con esos datos. Verifica teléfono, DNI o correo.';
      }

      if (!mounted) return;
      AppSnackbars.error(context, mensaje);
    } catch (error) {
      if (!mounted) return;
      AppSnackbars.error(context, _functionErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);
    final availableVehiclesAsync = ref.watch(adminAvailableVehiclesProvider);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        leading: AppBarLeadingBack(fallbackRoute: AppRoutes.adminHome),
        title: const Text('Nuevo conductor'),
      ),
      body: availableVehiclesAsync.when(
        data: (vehicles) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              _SectionCard(
                title: 'Datos personales',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => _requiredValidator(value, 'El nombre'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _apellidoController,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (value) => _requiredValidator(value, 'El apellido'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'DNI', hintText: '8 dígitos'),
                      validator: (value) {
                        final required = _requiredValidator(value, 'El DNI');
                        if (required != null) return required;
                        return RegExp(r'^\d{8}$').hasMatch(value!.trim())
                            ? null
                            : 'El DNI debe tener 8 dígitos';
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono', hintText: '9 dígitos'),
                      validator: (value) {
                        final required = _requiredValidator(value, 'El teléfono');
                        if (required != null) return required;
                        return RegExp(r'^\d{9}$').hasMatch(value!.trim())
                            ? null
                            : 'El teléfono debe tener 9 dígitos';
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final required = _requiredValidator(value, 'El email');
                        if (required != null) return required;
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
                            ? null
                            : 'Ingresa un email válido';
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _ocultarPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                          icon: Icon(
                            _ocultarPassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final required = _requiredValidator(value, 'La contraseña');
                        if (required != null) return required;
                        return value!.trim().length >= 8
                            ? null
                            : 'La contraseña debe tener al menos 8 caracteres';
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Vehículo asignado',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (vehicles.isEmpty) ...[
                      Text(
                        'No hay vehículos activos sin conductor asignado.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton(
                        onPressed: () => context.push(AppRoutes.adminVehiculosNuevo),
                        child: const Text('Crear vehículo primero'),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedVehicleId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Vehículo disponible'),
                        items: vehicles
                            .map(
                              (vehicle) => DropdownMenuItem<String>(
                                value: vehicle.id,
                                child: Text(
                                  '${vehicle.plate} · ${vehicle.vehicleType} · ${vehicle.capacity} asientos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => setState(() => _selectedVehicleId = value),
                        validator: (value) => value == null ? 'Selecciona un vehículo' : null,
                      ),
                    ],
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
                onPressed: _guardando || vehicles.isEmpty ? null : () => _guardar(vehicles),
                child: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Registrar conductor'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No se pudieron cargar los vehículos disponibles.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
