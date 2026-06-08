import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/favorite_pickups_provider.dart';
import '../providers/reserva_provider.dart';

class PickupReservaScreen extends ConsumerStatefulWidget {
  const PickupReservaScreen({super.key});

  @override
  ConsumerState<PickupReservaScreen> createState() => _PickupReservaScreenState();
}

class _PickupReservaScreenState extends ConsumerState<PickupReservaScreen> {
  late final TextEditingController _controller;
  bool _saveAsFavorite = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reserva = ref.read(reservaProvider);
    final session = ref.read(passengerSessionProvider);

    final preferred = session.account?.preferredPickup?.trim();
    final current = reserva.puntoRecojo?.trim();

    final initial = (current != null && current.isNotEmpty)
        ? current
        : (preferred != null && preferred.isNotEmpty)
            ? preferred
            : '';

    if (_controller.text != initial) {
      _controller.text = initial;
    }
  }

  bool _isValid(String value) => value.trim().length >= 3;

  @override
  Widget build(BuildContext context) {
    final reserva = ref.watch(reservaProvider);
    final controller = ref.read(reservaProvider.notifier);
    final favorites = ref.read(favoritePickupsProvider.notifier);
    final favoritePickups = ref.watch(favoritePickupsProvider);
    final driver = reserva.conductorSeleccionado;

    if (driver == null) {
      return const AppScaffold(
        title: 'Punto de recojo',
        body: PlaceholderPage(
          title: 'Reserva incompleta',
          subtitle: 'Vuelve a seleccionar conductor y asientos.',
        ),
      );
    }

    final value = _controller.text;
    final valid = _isValid(value);

    return AppScaffold(
      title: 'Punto de recojo',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ruta del conductor',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    driver.routeLabel,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '¿Dónde te recogemos?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Punto de recojo',
              hintText: 'Ej: Cruce con Av. Javier Prado, frente al grifo',
              errorText: value.isEmpty || valid ? null : 'Mínimo 3 caracteres',
            ),
          ),
          if (favoritePickups.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Puntos guardados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: favoritePickups
                  .map(
                    (p) => ActionChip(
                      label: Text(
                        p,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        _controller.text = p;
                        setState(() {});
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _saveAsFavorite,
            onChanged: (v) => setState(() => _saveAsFavorite = v ?? false),
            title: const Text('Guardar este punto como favorito'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Continuar',
            onPressed: valid
                ? () {
                    controller.setPickup(_controller.text);
                    if (_saveAsFavorite) {
                      favorites.add(_controller.text);
                    }
                    context.push(AppRoutes.passengerReservaResumen);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
