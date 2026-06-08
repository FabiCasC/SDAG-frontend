import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';

class AdminConductorCrearScreen extends ConsumerStatefulWidget {
  const AdminConductorCrearScreen({super.key});

  @override
  ConsumerState<AdminConductorCrearScreen> createState() => _AdminConductorCrearScreenState();
}

class _AdminConductorCrearScreenState extends ConsumerState<AdminConductorCrearScreen> {
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _dniController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  late final TextEditingController _placaController;
  late final TextEditingController _comisionController;

  String _vehiculoTipo = 'Toyota Hiace';
  int _capacidad = 8;
  double _comision = 15.0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController();
    _apellidosController = TextEditingController();
    _dniController = TextEditingController();
    _telefonoController = TextEditingController();
    _correoController = TextEditingController();
    _placaController = TextEditingController();
    _comisionController = TextEditingController(text: _comision.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _placaController.dispose();
    _comisionController.dispose();
    super.dispose();
  }

  void _syncComisionFromText() {
    final raw = _comisionController.text.replaceAll(',', '.').trim();
    final parsed = double.tryParse(raw);
    if (parsed == null) return;
    final clamped = parsed.clamp(0.0, 30.0);
    if (clamped == _comision) return;
    setState(() => _comision = clamped);
  }

  void _syncComisionTextFromSlider() {
    final nextText = _comision.toStringAsFixed(1);
    if (_comisionController.text.trim() == nextText) return;
    _comisionController.text = nextText;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _submitting = false);

    final nombreCompleto = '${_nombresController.text.trim()} ${_apellidosController.text.trim()}'.trim();
    final placa = _placaController.text.trim().toUpperCase();
    final correo = _correoController.text.trim();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar registro'),
        content: Text(
          '¿Registrar a $nombreCompleto con placa $placa?\n\n'
          'Se crearán sus credenciales de acceso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;

    final controller = ref.read(adminConductoresProvider.notifier);
    final result = controller.crearConductor(
      nombres: _nombresController.text,
      apellidos: _apellidosController.text,
      dni: _dniController.text,
      telefono: _telefonoController.text,
      correo: _correoController.text,
      placa: _placaController.text,
      vehiculoTipo: _vehiculoTipo,
      capacidad: _capacidad,
      comisionPorcentaje: _comision,
    );

    switch (result.type) {
      case AdminCrearConductorResultType.ok:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Conductor registrado. Credenciales enviadas a $correo'),
          ),
        );
        context.go('/admin/conductores/${result.createdId}');
        return;
      case AdminCrearConductorResultType.duplicateDni:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppColors.error, content: Text('DNI duplicado')),
        );
        return;
      case AdminCrearConductorResultType.duplicatePlaca:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppColors.error, content: Text('Placa duplicada')),
        );
        return;
      case AdminCrearConductorResultType.invalid:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text(result.message ?? 'Datos inválidos')),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final state = ref.watch(adminConductoresProvider);
    final dni = _dniController.text.trim();
    final placa = _placaController.text.trim().toUpperCase();

    final dniValid = RegExp(r'^\d{8}$').hasMatch(dni);
    final placaValid = RegExp(r'^[A-Z]{3}-\d{3}$').hasMatch(placa);
    final telefonoRaw = _telefonoController.text.trim();
    final telefonoValid = telefonoRaw.isEmpty || RegExp(r'^\d{9}$').hasMatch(telefonoRaw);
    final correo = _correoController.text.trim();
    final correoValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo);

    final dniDuplicado = dniValid && state.listaConductores.any((e) => e.dni == dni);
    final placaDuplicada = placaValid && state.listaConductores.any((e) => e.placa.toUpperCase() == placa);

    final nombresOk = _nombresController.text.trim().isNotEmpty;
    final apellidosOk = _apellidosController.text.trim().isNotEmpty;
    final comisionOk = _comision > 0 && _comision <= 30;

    final canSubmit = nombresOk &&
        apellidosOk &&
        dniValid &&
        !dniDuplicado &&
        telefonoValid &&
        correoValid &&
        placaValid &&
        !placaDuplicada &&
        comisionOk;

    final sampleComision = (480.0 * _comision / 100);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Nuevo conductor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          _SectionCard(
            title: 'Datos personales',
            child: Column(
              children: [
                TextField(
                  controller: _nombresController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    errorText: nombresOk ? null : 'Obligatorio',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _apellidosController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Apellidos',
                    errorText: apellidosOk ? null : 'Obligatorio',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _dniController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'DNI',
                    hintText: '8 dígitos',
                    errorText: !dniValid
                        ? (dni.isEmpty ? 'Obligatorio' : 'Debe tener 8 dígitos')
                        : (dniDuplicado ? 'DNI duplicado' : null),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _telefonoController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '9 dígitos',
                    errorText: telefonoValid ? null : 'Teléfono inválido',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _correoController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'correo@ejemplo.com',
                    errorText: correoValid ? null : (correo.isEmpty ? 'Obligatorio' : 'Correo inválido'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Datos del vehículo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _placaController,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Placa del vehículo',
                    hintText: 'ABC-123',
                    errorText: !placaValid
                        ? (placa.isEmpty ? 'Obligatorio' : 'Formato inválido (ABC-123)')
                        : (placaDuplicada ? 'Placa duplicada' : null),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tipo de vehículo'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _vehiculoTipo,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                        DropdownMenuItem(value: 'Van', child: Text('Van')),
                        DropdownMenuItem(value: 'Combi', child: Text('Combi')),
                        DropdownMenuItem(value: 'Nissan Urvan', child: Text('Nissan Urvan')),
                        DropdownMenuItem(value: 'Toyota Hiace', child: Text('Toyota Hiace')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _vehiculoTipo = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Capacidad',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [4, 6, 8, 15]
                      .map(
                        (v) => ChoiceChip(
                          label: Text('$v'),
                          selected: _capacidad == v,
                          onSelected: (_) => setState(() => _capacidad = v),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Este vehículo quedará asignado permanentemente a este conductor.\n'
                  'Solo el administrador puede modificarlo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Configuración de comisión',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _comision,
                        min: 0,
                        max: 30,
                        divisions: 60,
                        onChanged: (v) {
                          setState(() => _comision = v);
                          _syncComisionTextFromSlider();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: TextField(
                        controller: _comisionController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _syncComisionFromText(),
                        decoration: const InputDecoration(
                          labelText: '%',
                        ),
                      ),
                    ),
                  ],
                ),
                if (!comisionOk)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Ingresa un valor mayor a 0 y hasta 30%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Con ${_comision.toStringAsFixed(1)}%: si el conductor recauda S/480,\n'
                  'su comisión será S/ ${sampleComision.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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
            onPressed: (!canSubmit || _submitting) ? null : _submit,
            child: _submitting
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

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
