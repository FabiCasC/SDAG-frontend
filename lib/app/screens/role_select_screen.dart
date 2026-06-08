import 'package:flutter/material.dart';

import '../../data/models/app_role.dart';
import '../router/app_routes.dart';
import '../state/app_state_scope.dart';
import '../../shared/design/app_spacing.dart';
import '../../shared/widgets/reusable_ui_components.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppStateScope.of(context);
    final email = session.email ?? 'demo@sdag.pe';

    return AppScaffold(
      title: 'Seleccionar rol',
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () {
            session.logout();
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login,
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                email,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleButton(
                role: AppRole.passenger,
                onPressed: () => _select(context, AppRole.passenger),
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoleButton(
                role: AppRole.driver,
                onPressed: () => _select(context, AppRole.driver),
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoleButton(
                role: AppRole.admin,
                onPressed: () => _select(context, AppRole.admin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, AppRole role) {
    final session = AppStateScope.of(context);
    session.setRole(role);

    final next = switch (role) {
      AppRole.passenger => AppRoutes.passengerHome,
      AppRole.driver => AppRoutes.driverHome,
      AppRole.admin => AppRoutes.adminHome,
    };

    Navigator.of(context).pushNamedAndRemoveUntil(next, (_) => false);
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({required this.role, required this.onPressed});

  final AppRole role;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = switch (role) {
      AppRole.passenger => Icons.person,
      AppRole.driver => Icons.local_taxi,
      AppRole.admin => Icons.admin_panel_settings,
    };

    return AppPrimaryButton(
      label: 'Ingresar como ${role.label}',
      icon: icon,
      onPressed: onPressed,
    );
  }
}
