import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';

class AdminConductorEditarScreen extends ConsumerStatefulWidget {
  const AdminConductorEditarScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<AdminConductorEditarScreen> createState() => _AdminConductorEditarScreenState();
}

class _AdminConductorEditarScreenState extends ConsumerState<AdminConductorEditarScreen> {
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
  double _comisionOriginal = 15.0;
  bool _saving = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController();
    _apellidosController = TextEditingController();
    _dniController = TextEditingController();
    _telefonoController = TextEditingController();
    _correoController = TextEditingController();
    _placaController = TextEditingController();
    _comisionController = TextEditingController();
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

  Future<void> _save(Map<String, dynamic> current) async {
    if (_saving) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final placa = _placaController.text.trim().toUpperCase();
    final dni = _dniController.text.trim();
    final correo = _correoController.text.trim();
    final nombresOk = _nombresController.text.trim().isNotEmpty;
    final apellidosOk = _apellidosController.text.trim().isNotEmpty;
    final dniValid = RegExp(r'^\d{8}$').hasMatch(dni);
    final placaValid = RegExp(r'^[A-Z]{3}-\d{3}$').hasMatch(placa);
    final telefonoRaw = _telefonoController.text.trim();
    final telefonoValid = telefonoRaw.isEmpty || RegExp(r'^\d{9}$').hasMatch(telefonoRaw);
    final correoValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo);

    final state = ref.read(adminConductoresProvider);
    final placaDuplicada = placaValid && state.listaConductores.any((e) => e['id'] != current['id'] && (e['placa']?.toString() ?? '').toUpperCase() == placa);

    final canSave = nombresOk && apellidosOk && dniValid && placaValid && telefonoValid && correoValid && !placaDuplicada;
    if (!canSave) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.error, content: Text('Revisa los campos del formulario')),
      );
      return;
    }

    final controller = ref.read(adminConductoresProvider.notifier);
    final edit = await controller.editarConductor(
      id: current['id']?.toString() ?? '',
      telefono: _telefonoController.text,
      correo: _correoController.text,
      placa: _placaController.text,
      capacidad: _capacidad,
      comisionPorcentaje: (current['comisionPorcentaje'] as num?)?.toDouble() ?? 15.0,
      cuentaActiva: current['estado'] != 'inactivo',
    );
    if (!mounted) return;

    if (edit.type == AdminEditarConductorResultType.duplicatePlaca) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.error, content: Text('Placa duplicada')),
      );
      return;
    }
    if (edit.type != AdminEditarConductorResultType.ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(edit.message ?? 'No se pudo guardar')),
      );
      return;
    }

    if (_comision != _comisionOriginal && _comision > 0 && _comision <= 30) {
      controller.actualizarComision(current['id']?.toString() ?? '', _comision);
    }

    final now = DateTime.now();
    final stamp = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.success, content: Text('Cambios guardados con fecha $stamp')),
    );
    if (!mounted) return;
    context.go('/admin/conductores/${current['id']?.toString() ?? ''}');
  }

  @override
  Widget build(BuildContext context) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final state = ref.watch(adminConductoresProvider);
    final current = ref.read(adminConductoresProvider.notifier).getById(widget.id);
    if (current == null) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(title: const Text('Editar')),
        body: const Center(child: Text('No se encontró el conductor.')),
      );
    }

    if (!_prefilled) {
      _prefilled = true;
      _nombresController.text = current['nombres']?.toString() ?? '';
      _apellidosController.text = current['apellidos']?.toString() ?? '';
      _dniController.text = current['dni']?.toString() ?? '';
      final tel = current['telefono']?.toString() ?? '';
      _telefonoController.text = tel == '—' ? '' : tel;
      _correoController.text = current['correo']?.toString() ?? '';
      _placaController.text = current['placa']?.toString() ?? '';
      _vehiculoTipo = current['vehiculoTipo']?.toString() ?? 'Toyota Hiace';
      _capacidad = (current['capacidad'] as num?)?.toInt() ?? 8;
      final pendiente = (current['comisionPendientePorcentaje'] as num?)?.toDouble();
      final actual = (current['comisionPorcentaje'] as num?)?.toDouble() ?? 15.0;
      _comisionOriginal = pendiente ?? actual;
      _comision = _comisionOriginal;
      _comisionController.text = _comision.toStringAsFixed(1);
    }

    final dni = _dniController.text.trim();
    final placa = _placaController.text.trim().toUpperCase();
    final dniValid = RegExp(r'^\d{8}$').hasMatch(dni);
    final placaValid = RegExp(r'^[A-Z]{3}-\d{3}$').hasMatch(placa);
    final telefonoRaw = _telefonoController.text.trim();
    final telefonoValid = telefonoRaw.isEmpty || RegExp(r'^\d{9}$').hasMatch(telefonoRaw);
    final correo = _correoController.text.trim();
    final correoValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo);

    final placaDuplicada = placaValid && state.listaConductores.any((e) => e['id'] != current['id'] && (e['placa']?.toString() ?? '').toUpperCase() == placa);

    final nombresOk = _nombresController.text.trim().isNotEmpty;
    final apellidosOk = _apellidosController.text.trim().isNotEmpty;

    final sampleComision = (480.0 * _comision / 100);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: Text('Editar ${current['placa']?.toString() ?? ''}'),
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
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'DNI',
                    errorText: dniValid ? null : 'Debe tener 8 dígitos',
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
                    errorText: correoValid ? null : 'Correo inválido',
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
                        decoration: const InputDecoration(labelText: '%'),
                      ),
                    ),
                  ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
            ),
            onPressed: _saving ? null : () => _save(current),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : const Text('Guardar cambios'),
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
