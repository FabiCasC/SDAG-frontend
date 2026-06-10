import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/maps/widgets/map_pick_address_sheet.dart';
import '../../../shared/maps/widgets/places_address_search_field.dart';
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
  final _placesSearch = TextEditingController();
  bool _saveAsFavorite = false;

  String _preferredFromProfile = '';
  List<String> _routePickupAddresses = const [];
  bool _loadingContext = true;
  String? _contextError;
  String? _loadedTripId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _placesSearch.dispose();
    super.dispose();
  }

  Future<void> _loadContextForTrip(String tripId) async {
    setState(() {
      _loadingContext = true;
      _contextError = null;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      var preferred = '';
      if (userId != null) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('preferred_pickup')
            .eq('id', userId)
            .maybeSingle();
        preferred = row?['preferred_pickup']?.toString().trim() ?? '';
      }

      final trip = await Supabase.instance.client.from('trips').select('route_id').eq('id', tripId).maybeSingle();
      final routeId = trip?['route_id']?.toString();
      var routePoints = <String>[];
      if (routeId != null && routeId.isNotEmpty) {
        final pts = await Supabase.instance.client
            .from('pickup_points')
            .select('address')
            .eq('route_id', routeId)
            .order('address', ascending: true);
        for (final raw in pts as List) {
          final m = Map<String, dynamic>.from(raw as Map);
          final a = m['address']?.toString().trim();
          if (a != null && a.isNotEmpty) routePoints.add(a);
        }
      }

      if (!mounted) return;
      setState(() {
        _preferredFromProfile = preferred;
        _routePickupAddresses = routePoints;
        _loadingContext = false;
      });
      _syncInitialPickup();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingContext = false;
        _contextError = e.toString();
      });
    }
  }

  void _syncInitialPickup() {
    final reserva = ref.read(reservaProvider);
    final current = reserva.puntoRecojo?.trim();
    if (current != null && current.isNotEmpty) {
      _controller.text = current;
      _placesSearch.text = current;
      return;
    }
    if (_preferredFromProfile.isNotEmpty) {
      _controller.text = _preferredFromProfile;
      _placesSearch.text = _preferredFromProfile;
      return;
    }
    if (_routePickupAddresses.isNotEmpty) {
      _controller.text = _routePickupAddresses.first;
      _placesSearch.text = _routePickupAddresses.first;
    }
  }

  void _selectAddress(String value) {
    _controller.text = value;
    _placesSearch.text = value;
    setState(() {});
  }

  bool _isValid(String value) => value.trim().length >= 3;

  Future<void> _openMapPicker() async {
    final addr = await showMapPickAddressSheet(context);
    if (!mounted || addr == null || addr.trim().isEmpty) return;
    _selectAddress(addr.trim());
  }

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

    if (_loadedTripId != driver.tripId) {
      _loadedTripId = driver.tripId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadContextForTrip(driver.tripId);
      });
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
          if (_loadingContext) const LinearProgressIndicator(),
          if (_contextError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'No se pudieron cargar los puntos de ruta: $_contextError',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          Text(
            '¿Dónde te recogemos?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_preferredFromProfile.isNotEmpty) ...[
            Text(
              'Tu punto favorito',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: ChoiceChip(
                label: Text(_preferredFromProfile, overflow: TextOverflow.ellipsis),
                selected: value.trim() == _preferredFromProfile,
                onSelected: (_) => _selectAddress(_preferredFromProfile),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_routePickupAddresses.isNotEmpty) ...[
            Text(
              'Puntos de la ruta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _routePickupAddresses.map((p) {
                return ChoiceChip(
                  label: Text(p, overflow: TextOverflow.ellipsis),
                  selected: value.trim() == p,
                  onSelected: (_) => _selectAddress(p),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Buscar otra dirección (Google Places)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PlacesAddressSearchField(
            controller: _placesSearch,
            label: 'Dirección en Perú',
            hint: 'Ej: Av. Javier Prado, San Isidro',
            onAddressResolved: (formatted) => _selectAddress(formatted),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _openMapPicker,
            icon: const Icon(Icons.map_rounded),
            label: const Text('Elegir en el mapa'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Punto de recojo final',
              hintText: 'Se rellena al elegir arriba; puedes editarlo',
              errorText: value.isEmpty || valid ? null : 'Mínimo 3 caracteres',
            ),
          ),
          if (favoritePickups.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Puntos guardados (local)',
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
                      label: Text(p, overflow: TextOverflow.ellipsis),
                      onPressed: () => _selectAddress(p),
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
            title: const Text('Guardar como punto favorito en mi perfil'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Continuar',
            onPressed: valid && !_loadingContext
                ? () async {
                    final text = _controller.text.trim();
                    controller.setPickup(text);
                    if (_saveAsFavorite) {
                      favorites.add(text);
                      final uid = Supabase.instance.client.auth.currentUser?.id;
                      if (uid != null) {
                        try {
                          await Supabase.instance.client
                              .from('profiles')
                              .update({'preferred_pickup': text}).eq('id', uid);
                        } catch (_) {}
                      }
                    }
                    if (context.mounted) context.push(AppRoutes.passengerReservaResumen);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
