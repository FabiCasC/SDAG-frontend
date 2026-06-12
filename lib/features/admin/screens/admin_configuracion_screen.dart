import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../passenger/screens/viajes_service.dart';

final adminConfiguracionProvider =
    StateNotifierProvider<AdminConfiguracionController, AdminConfiguracionState>(
  (ref) => AdminConfiguracionController(),
);

class AdminConfiguracionState {
  const AdminConfiguracionState({
    required this.saved,
    required this.draft,
    required this.loading,
    required this.saving,
  });

  final AdminSystemConfig saved;
  final AdminSystemConfig draft;
  final bool loading;
  final bool saving;

  bool get hasChanges => saved != draft;
  bool get priceValid => draft.basePrice > 0;
  bool get rucValid => RegExp(r'^\d{11}$').hasMatch(draft.companyRuc.trim());
  bool get emailValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(draft.supportEmail.trim());
  bool get isValid => priceValid && rucValid && emailValid;

  AdminConfiguracionState copyWith({
    AdminSystemConfig? saved,
    AdminSystemConfig? draft,
    bool? loading,
    bool? saving,
  }) {
    return AdminConfiguracionState(
      saved: saved ?? this.saved,
      draft: draft ?? this.draft,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
    );
  }

  static AdminConfiguracionState initial() => AdminConfiguracionState(
        saved: AdminSystemConfig.defaults(),
        draft: AdminSystemConfig.defaults(),
        loading: true,
        saving: false,
      );
}

class AdminSystemConfig {
  const AdminSystemConfig({
    required this.basePrice,
    required this.operatingStartMin,
    required this.operatingEndMin,
    required this.runMonFri,
    required this.runSat,
    required this.runSun,
    required this.companyName,
    required this.companyRuc,
    required this.contactPhone,
    required this.supportEmail,
  });

  final double basePrice;
  final int operatingStartMin;
  final int operatingEndMin;
  final bool runMonFri;
  final bool runSat;
  final bool runSun;
  final String companyName;
  final String companyRuc;
  final String contactPhone;
  final String supportEmail;

  static AdminSystemConfig defaults() {
    return const AdminSystemConfig(
      basePrice: 15.0,
      operatingStartMin: 5 * 60,
      operatingEndMin: 22 * 60,
      runMonFri: true,
      runSat: true,
      runSun: true,
      companyName: 'SDAG',
      companyRuc: '20123456789',
      contactPhone: '01 234 5678',
      supportEmail: 'soporte@sdag.pe',
    );
  }

  AdminSystemConfig copyWith({
    double? basePrice,
    int? operatingStartMin,
    int? operatingEndMin,
    bool? runMonFri,
    bool? runSat,
    bool? runSun,
    String? companyName,
    String? companyRuc,
    String? contactPhone,
    String? supportEmail,
  }) {
    return AdminSystemConfig(
      basePrice: basePrice ?? this.basePrice,
      operatingStartMin: operatingStartMin ?? this.operatingStartMin,
      operatingEndMin: operatingEndMin ?? this.operatingEndMin,
      runMonFri: runMonFri ?? this.runMonFri,
      runSat: runSat ?? this.runSat,
      runSun: runSun ?? this.runSun,
      companyName: companyName ?? this.companyName,
      companyRuc: companyRuc ?? this.companyRuc,
      contactPhone: contactPhone ?? this.contactPhone,
      supportEmail: supportEmail ?? this.supportEmail,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminSystemConfig &&
        other.basePrice == basePrice &&
        other.operatingStartMin == operatingStartMin &&
        other.operatingEndMin == operatingEndMin &&
        other.runMonFri == runMonFri &&
        other.runSat == runSat &&
        other.runSun == runSun &&
        other.companyName == companyName &&
        other.companyRuc == companyRuc &&
        other.contactPhone == contactPhone &&
        other.supportEmail == supportEmail;
  }

  @override
  int get hashCode => Object.hash(
        basePrice,
        operatingStartMin,
        operatingEndMin,
        runMonFri,
        runSat,
        runSun,
        companyName,
        companyRuc,
        contactPhone,
        supportEmail,
      );
}

class AdminConfiguracionController extends StateNotifier<AdminConfiguracionState> {
  AdminConfiguracionController() : super(AdminConfiguracionState.initial()) {
    _load();
  }

  static const _basePriceKey = 'sdag_system_base_price';
  static const _startMinKey = 'sdag_system_operating_start_min';
  static const _endMinKey = 'sdag_system_operating_end_min';
  static const _runMonFriKey = 'sdag_system_operating_monfri';
  static const _runSatKey = 'sdag_system_operating_sat';
  static const _runSunKey = 'sdag_system_operating_sun';
  static const _companyNameKey = 'sdag_system_company_name';
  static const _companyRucKey = 'sdag_system_company_ruc';
  static const _contactPhoneKey = 'sdag_system_contact_phone';
  static const _supportEmailKey = 'sdag_system_support_email';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AdminSystemConfig.defaults();
    final loaded = AdminSystemConfig(
      basePrice: prefs.getDouble(_basePriceKey) ?? defaults.basePrice,
      operatingStartMin: prefs.getInt(_startMinKey) ?? defaults.operatingStartMin,
      operatingEndMin: prefs.getInt(_endMinKey) ?? defaults.operatingEndMin,
      runMonFri: prefs.getBool(_runMonFriKey) ?? defaults.runMonFri,
      runSat: prefs.getBool(_runSatKey) ?? defaults.runSat,
      runSun: prefs.getBool(_runSunKey) ?? defaults.runSun,
      companyName: prefs.getString(_companyNameKey) ?? defaults.companyName,
      companyRuc: prefs.getString(_companyRucKey) ?? defaults.companyRuc,
      contactPhone: prefs.getString(_contactPhoneKey) ?? defaults.contactPhone,
      supportEmail: prefs.getString(_supportEmailKey) ?? defaults.supportEmail,
    );
    state = state.copyWith(saved: loaded, draft: loaded, loading: false);
  }

  void setBasePrice(double value) {
    state = state.copyWith(draft: state.draft.copyWith(basePrice: value));
  }

  void setOperatingStart(TimeOfDay v) {
    state = state.copyWith(draft: state.draft.copyWith(operatingStartMin: v.hour * 60 + v.minute));
  }

  void setOperatingEnd(TimeOfDay v) {
    state = state.copyWith(draft: state.draft.copyWith(operatingEndMin: v.hour * 60 + v.minute));
  }

  void setRunMonFri(bool v) {
    state = state.copyWith(draft: state.draft.copyWith(runMonFri: v));
  }

  void setRunSat(bool v) {
    state = state.copyWith(draft: state.draft.copyWith(runSat: v));
  }

  void setRunSun(bool v) {
    state = state.copyWith(draft: state.draft.copyWith(runSun: v));
  }

  void setCompanyName(String v) {
    state = state.copyWith(draft: state.draft.copyWith(companyName: v));
  }

  void setCompanyRuc(String v) {
    state = state.copyWith(draft: state.draft.copyWith(companyRuc: v));
  }

  void setContactPhone(String v) {
    state = state.copyWith(draft: state.draft.copyWith(contactPhone: v));
  }

  void setSupportEmail(String v) {
    state = state.copyWith(draft: state.draft.copyWith(supportEmail: v));
  }

  Future<void> save() async {
    final next = state.draft;
    if (next.basePrice <= 0) return;

    state = state.copyWith(saving: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_basePriceKey, next.basePrice);
    await prefs.setInt(_startMinKey, next.operatingStartMin);
    await prefs.setInt(_endMinKey, next.operatingEndMin);
    await prefs.setBool(_runMonFriKey, next.runMonFri);
    await prefs.setBool(_runSatKey, next.runSat);
    await prefs.setBool(_runSunKey, next.runSun);
    await prefs.setString(_companyNameKey, next.companyName.trim());
    await prefs.setString(_companyRucKey, next.companyRuc.trim());
    await prefs.setString(_contactPhoneKey, next.contactPhone.trim());
    await prefs.setString(_supportEmailKey, next.supportEmail.trim());

    state = state.copyWith(saved: next, saving: false);
  }
}

class AdminConfiguracionScreen extends ConsumerStatefulWidget {
  const AdminConfiguracionScreen({super.key});

  @override
  ConsumerState<AdminConfiguracionScreen> createState() => _AdminConfiguracionScreenState();
}

class _AdminConfiguracionScreenState extends ConsumerState<AdminConfiguracionScreen> {
  late final TextEditingController _precioController;
  late final TextEditingController _empresaController;
  late final TextEditingController _rucController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoSoporteController;

  late final ProviderSubscription<AdminConfiguracionState> _sub;
  bool _didSyncOnce = false;

  @override
  void initState() {
    super.initState();
    _precioController = TextEditingController();
    _empresaController = TextEditingController();
    _rucController = TextEditingController();
    _telefonoController = TextEditingController();
    _correoSoporteController = TextEditingController();
    _sub = ref.listenManual<AdminConfiguracionState>(
      adminConfiguracionProvider,
      (prev, next) {
        if (_didSyncOnce) return;
        if (next.loading) return;
        _didSyncOnce = true;
        _precioController.text = next.draft.basePrice.toStringAsFixed(2);
        _empresaController.text = next.draft.companyName;
        _rucController.text = next.draft.companyRuc;
        _telefonoController.text = next.draft.contactPhone;
        _correoSoporteController.text = next.draft.supportEmail;
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _sub.close();
    _precioController.dispose();
    _empresaController.dispose();
    _rucController.dispose();
    _telefonoController.dispose();
    _correoSoporteController.dispose();
    super.dispose();
  }

  TimeOfDay _timeFromMin(int min) {
    final h = (min ~/ 60) % 24;
    final m = min % 60;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) {
    final dt = DateTime(2025, 1, 1, t.hour, t.minute);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _pickStart(TimeOfDay current) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    ref.read(adminConfiguracionProvider.notifier).setOperatingStart(picked);
  }

  Future<void> _pickEnd(TimeOfDay current) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    ref.read(adminConfiguracionProvider.notifier).setOperatingEnd(picked);
  }

  double? _parsePrice(String raw) {
    final v = double.tryParse(raw.replaceAll(',', '.').trim());
    return v;
  }

  Future<void> _saveFlow(AdminConfiguracionState s) async {
    final controller = ref.read(adminConfiguracionProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final reservasActivas = await ViajesService().obtenerConteoReservasActivas();
    final priceChanged = s.draft.basePrice != s.saved.basePrice;

    if (!s.isValid) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Revisa los campos de configuración'),
        ),
      );
      return;
    }

    if (priceChanged && reservasActivas > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Advertencia'),
          content: Text(
            'Hay $reservasActivas reservas activas en este momento.\n'
            'El nuevo precio aplicará únicamente a las próximas reservas. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aplicar de todas formas'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (ok != true) return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmación'),
        content: const Text('¿Aplicar los cambios de configuración?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm != true) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF97316)),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();

    await controller.save();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Configuración actualizada correctamente'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final s = ref.watch(adminConfiguracionProvider);
    final controller = ref.read(adminConfiguracionProvider.notifier);

    final start = _timeFromMin(s.draft.operatingStartMin);
    final end = _timeFromMin(s.draft.operatingEndMin);

    final priceError = s.draft.basePrice <= 0 ? 'El valor debe ser mayor a 0' : null;
    final rucError = s.rucValid ? null : 'RUC inválido (11 dígitos)';
    final emailError = s.emailValid ? null : 'Correo inválido';

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Configuración general'),
      ),
      body: s.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.p20),
              children: [
                _SectionCard(
                  title: 'Precio base por asiento',
                  leftBorderColor: const Color(0xFFDC2626),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'S/ ${s.saved.basePrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _precioController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Nuevo precio (S/)',
                          errorText: priceError,
                        ),
                        onChanged: (v) {
                          final parsed = _parsePrice(v);
                          if (parsed == null) return;
                          controller.setBasePrice(parsed);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'IMPORTANTE: El cambio solo aplicará a reservas futuras.\n'
                        'Las reservas ya confirmadas mantienen el precio actual.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Horario operativo',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickStart(start),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.r12),
                                ),
                              ),
                              child: Text('Inicio: ${_formatTime(start)}'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickEnd(end),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.r12),
                                ),
                              ),
                              child: Text('Fin: ${_formatTime(end)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'El sistema opera 24/7. Esta configuración es solo informativa.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: s.draft.runMonFri,
                        onChanged: (v) => controller.setRunMonFri(v ?? false),
                        title: const Text('Lunes a Viernes'),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: s.draft.runSat,
                        onChanged: (v) => controller.setRunSat(v ?? false),
                        title: const Text('Sábado'),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: s.draft.runSun,
                        onChanged: (v) => controller.setRunSun(v ?? false),
                        title: const Text('Domingo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Datos de la empresa',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _empresaController,
                        decoration: const InputDecoration(labelText: 'Nombre de la empresa'),
                        onChanged: controller.setCompanyName,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _rucController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'RUC',
                          hintText: '11 dígitos',
                          errorText: rucError,
                        ),
                        onChanged: controller.setCompanyRuc,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Teléfono de contacto'),
                        onChanged: controller.setContactPhone,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _correoSoporteController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo de soporte',
                          errorText: emailError,
                        ),
                        onChanged: controller.setSupportEmail,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Estos datos aparecen en el manifiesto electrónico.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
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
                  onPressed: (!s.hasChanges || s.saving) ? null : () => _saveFlow(s),
                  child: const Text('Guardar configuración'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.adminHome),
                  child: const Text('Volver al panel'),
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.leftBorderColor,
  });

  final String title;
  final Widget child;
  final Color? leftBorderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border(
          left: BorderSide(color: leftBorderColor ?? AppColors.border, width: leftBorderColor == null ? 1 : 6),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
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
