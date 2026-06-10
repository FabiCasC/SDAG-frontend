import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../design/app_spacing.dart';
import '../google_places_service.dart';
import 'places_address_search_field.dart';

/// Hoja inferior: mapa + toque para elegir punto; geocodificación inversa a texto.
Future<String?> showMapPickAddressSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _MapPickBody(),
  );
}

class _MapPickBody extends StatefulWidget {
  const _MapPickBody();

  @override
  State<_MapPickBody> createState() => _MapPickBodyState();
}

class _MapPickBodyState extends State<_MapPickBody> {
  static const _lima = LatLng(-12.0464, -77.0428);

  GoogleMapController? _mapController;
  LatLng? _picked;
  String? _resolved;
  bool _busy = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _resolve(LatLng pos) async {
    setState(() {
      _picked = pos;
      _busy = true;
      _resolved = null;
    });
    final addr = await GooglePlacesService.reverseGeocode(pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _resolved = addr ?? '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    });
  }

  Future<void> _moveToPlaceId(String placeId) async {
    final pos = await GooglePlacesService.latLngForPlaceId(placeId);
    if (!mounted || pos == null) return;
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
    await _resolve(pos);
  }

  @override
  Widget build(BuildContext context) {
    final markers = _picked == null
        ? const <Marker>{}
        : {
            Marker(
              markerId: const MarkerId('pick'),
              position: _picked!,
            ),
          };

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Elegir en el mapa',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          PlacesAddressSearchField(
            controller: _search,
            label: 'Buscar y centrar',
            hint: 'Escribe una dirección en Perú',
            onPlaceChosen: (p, _) async {
              await _moveToPlaceId(p.placeId);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: _lima, zoom: 13),
                markers: markers,
                onMapCreated: (c) => _mapController = c,
                onTap: (pos) => _resolve(pos),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Toca el mapa para colocar el pin.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_resolved != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_resolved!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              const Spacer(),
              FilledButton(
                onPressed: _resolved == null || _resolved!.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, _resolved!.trim()),
                child: const Text('Usar este punto'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
