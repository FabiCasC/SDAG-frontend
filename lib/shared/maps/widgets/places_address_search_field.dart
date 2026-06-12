import 'dart:async';

import 'package:flutter/material.dart';

import '../google_places_service.dart';

/// Campo de texto con sugerencias de Google Places (Perú), lista debajo del campo.
class PlacesAddressSearchField extends StatefulWidget {
  const PlacesAddressSearchField({
    super.key,
    required this.controller,
    this.label = 'Buscar dirección',
    this.hint = 'Escribe calle, distrito…',
    this.prefixIcon,
    this.onAddressResolved,
    this.onPlaceChosen,
    this.onTextEdited,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final void Function(String formattedAddress)? onAddressResolved;
  final void Function(PlacePrediction prediction, String displayText)? onPlaceChosen;
  final VoidCallback? onTextEdited;

  @override
  State<PlacesAddressSearchField> createState() => _PlacesAddressSearchFieldState();
}

class _PlacesAddressSearchFieldState extends State<PlacesAddressSearchField> {
  Timer? _debounce;
  List<PlacePrediction> _suggestions = const [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetch(String text) async {
    setState(() => _loading = true);
    try {
      final list = await GooglePlacesService.autocomplete(text);
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: (value) {
            widget.onTextEdited?.call();
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () {
              if (value.trim().length < 2) {
                setState(() => _suggestions = const []);
                return;
              }
              _fetch(value);
            });
          },
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = _suggestions[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_rounded),
                    title: Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      final formatted = await GooglePlacesService.formattedAddressForPlaceId(p.placeId);
                      final text = (formatted != null && formatted.isNotEmpty) ? formatted : p.description;
                      widget.controller.text = text;
                      widget.onAddressResolved?.call(text);
                      widget.onPlaceChosen?.call(p, text);
                      setState(() => _suggestions = const []);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
