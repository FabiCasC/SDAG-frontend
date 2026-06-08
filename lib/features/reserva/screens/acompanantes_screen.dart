import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

class AcompanantesScreen extends ConsumerStatefulWidget {
  const AcompanantesScreen({super.key});

  @override
  ConsumerState<AcompanantesScreen> createState() => _AcompanantesScreenState();
}

class _AcompanantesScreenState extends ConsumerState<AcompanantesScreen> {
  final Map<int, TextEditingController> _nameControllers = {};
  final Map<int, TextEditingController> _dniControllers = {};
  final Map<int, TextEditingController> _phoneControllers = {};

  List<int> _currentSeats = const [];

  @override
  void dispose() {
    for (final c in _nameControllers.values) {
      c.dispose();
    }
    for (final c in _dniControllers.values) {
      c.dispose();
    }
    for (final c in _phoneControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<int> seats, Map<int, ReservaAcompanante> existing) {
    if (_listEquals(_currentSeats, seats)) return;

    final keep = seats.toSet();
    _nameControllers.removeWhere((k, v) {
      if (!keep.contains(k)) {
        v.dispose();
        return true;
      }
      return false;
    });
    _dniControllers.removeWhere((k, v) {
      if (!keep.contains(k)) {
        v.dispose();
        return true;
      }
      return false;
    });
    _phoneControllers.removeWhere((k, v) {
      if (!keep.contains(k)) {
        v.dispose();
        return true;
      }
      return false;
    });

    for (final seat in seats) {
      final a = existing[seat];
      _nameControllers.putIfAbsent(seat, () => TextEditingController(text: a?.fullName ?? ''));
      _dniControllers.putIfAbsent(seat, () => TextEditingController(text: a?.dni ?? ''));
      _phoneControllers.putIfAbsent(seat, () => TextEditingController(text: a?.phone ?? ''));
    }

    _currentSeats = List<int>.from(seats);
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _isValidDni(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 8;
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 9;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservaProvider);
    final controller = ref.read(reservaProvider.notifier);

    final seatsSorted = [...state.asientosSeleccionados]..sort();
    if (seatsSorted.length <= 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.passengerReservaPickup);
      });
      return const AppScaffold(
        title: 'Acompañantes',
        body: SizedBox.shrink(),
      );
    }

    final companionSeats = seatsSorted.sublist(1);
    _syncControllers(companionSeats, state.acompanantes);

    final allValid = companionSeats.every((seat) {
      final name = _nameControllers[seat]?.text.trim() ?? '';
      final dni = _dniControllers[seat]?.text.trim() ?? '';
      final phone = _phoneControllers[seat]?.text.trim() ?? '';
      return name.isNotEmpty && _isValidDni(dni) && _isValidPhone(phone);
    });

    return AppScaffold(
      title: 'Acompañantes',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Completa los datos de tus acompañantes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              itemCount: companionSeats.length,
              itemBuilder: (context, index) {
                final seat = companionSeats[index];
                final nameCtrl = _nameControllers[seat]!;
                final dniCtrl = _dniControllers[seat]!;
                final phoneCtrl = _phoneControllers[seat]!;

                final dniOk = _isValidDni(dniCtrl.text);
                final phoneOk = _isValidPhone(phoneCtrl.text);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: DecoratedBox(
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
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Asiento $seat',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: nameCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: dniCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'DNI',
                              errorText: dniCtrl.text.isEmpty || dniOk ? null : 'Debe tener 8 dígitos',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Teléfono',
                              errorText:
                                  phoneCtrl.text.isEmpty || phoneOk ? null : 'Debe tener 9 dígitos',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Continuar',
            onPressed: allValid
                ? () {
                    for (final seat in companionSeats) {
                      controller.setAcompanante(
                        ReservaAcompanante(
                          seatNumber: seat,
                          fullName: _nameControllers[seat]!.text.trim(),
                          dni: _dniControllers[seat]!.text.replaceAll(RegExp(r'\D'), ''),
                          phone: _phoneControllers[seat]!.text.replaceAll(RegExp(r'\D'), ''),
                        ),
                      );
                    }
                    context.push(AppRoutes.passengerReservaPickup);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

