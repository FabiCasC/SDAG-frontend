import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_noticias_provider.dart';

class NuevaNoticiaScreen extends ConsumerStatefulWidget {
  const NuevaNoticiaScreen({super.key});

  @override
  ConsumerState<NuevaNoticiaScreen> createState() => _NuevaNoticiaScreenState();
}

class _NuevaNoticiaScreenState extends ConsumerState<NuevaNoticiaScreen> {
  MockNewsType _type = MockNewsType.incidencia;
  late final TextEditingController _title;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _desc = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _publish() {
    final title = _title.text.trim();
    final desc = _desc.text.trim();

    if (title.length < 5) {
      AppSnackbars.error(context, 'El título debe tener mínimo 5 caracteres');
      return;
    }
    if (desc.length < 10) {
      AppSnackbars.error(context, 'La descripción debe tener mínimo 10 caracteres');
      return;
    }

    ref.read(conductorNoticiasProvider.notifier).publicar(
          type: _type,
          title: title,
          description: desc,
        );
    AppSnackbars.success(context, 'Incidencia publicada. Visible para todos.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Nueva publicación'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            Text(
              'Tipo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.r16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  RadioGroup<MockNewsType>(
                    groupValue: _type,
                    onChanged: (v) => setState(() => _type = v ?? _type),
                    child: Column(
                      children: const [
                        RadioListTile<MockNewsType>(
                          value: MockNewsType.incidencia,
                          title: Text('Incidencia'),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        RadioListTile<MockNewsType>(
                          value: MockNewsType.novedad,
                          title: Text('Novedad'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Mínimo 5 caracteres',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _desc,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Mínimo 10 caracteres',
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
              onPressed: _publish,
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
