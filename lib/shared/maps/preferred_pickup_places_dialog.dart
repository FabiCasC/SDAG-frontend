import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design/app_spacing.dart';
import 'widgets/places_address_search_field.dart';

/// Diálogo para elegir y guardar `preferred_pickup` con Places.
Future<String?> showPreferredPickupPlacesDialog(BuildContext context) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final controller = TextEditingController();
  String? error;

  final saved = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Punto de recojo favorito'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Busca tu dirección habitual de recojo. La usaremos como opción predeterminada en tus reservas.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PlacesAddressSearchField(
                    controller: controller,
                    label: 'Dirección en Perú',
                    hint: 'Ej: Av. Javier Prado 123, San Isidro',
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Más tarde'),
              ),
              FilledButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.length < 3) {
                    setLocal(() => error = 'Elige o escribe una dirección válida (mín. 3 caracteres).');
                    return;
                  }
                  setLocal(() => error = null);
                  try {
                    await Supabase.instance.client.from('profiles').update({
                      'preferred_pickup': text,
                    }).eq('id', userId);
                    if (ctx.mounted) Navigator.pop(ctx, text);
                  } catch (e) {
                    setLocal(() => error = 'No se pudo guardar: $e');
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return saved;
}
