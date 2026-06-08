import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../features/viaje/screens/historial_screen.dart';
import '../../../features/noticias/screens/noticias_screen.dart';
import '../../../features/perfil/screens/perfil_screen.dart';
import '../../../features/reserva/providers/favorite_pickups_provider.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({required this.initialRoute, super.key});

  final String initialRoute;

  int _indexFromRoute(String route) {
    switch (route) {
      case AppRoutes.passengerTrips:
        return 1;
      case AppRoutes.passengerNews:
        return 2;
      case AppRoutes.passengerProfile:
        return 3;
      case AppRoutes.passengerHome:
      default:
        return 0;
    }
  }

  String _routeFromIndex(int index) {
    switch (index) {
      case 1:
        return AppRoutes.passengerTrips;
      case 2:
        return AppRoutes.passengerNews;
      case 3:
        return AppRoutes.passengerProfile;
      case 0:
      default:
        return AppRoutes.passengerHome;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _indexFromRoute(initialRoute);
    final session = ref.watch(passengerSessionProvider);
    final account = session.account;
    final fullName = [
      account?.firstName?.trim(),
      account?.lastName?.trim(),
    ].whereType<String>().where((v) => v.isNotEmpty).join(' ');
    final name = (account?.name?.trim().isNotEmpty ?? false)
        ? account!.name!.trim()
        : fullName.isNotEmpty
            ? fullName
            : MockData.passengerName;
    final reserva = ref.watch(reservaProvider);
    final hasActiveReservation = reserva.conductorSeleccionado != null &&
        reserva.reservaId != null &&
        reserva.asientosSeleccionados.isNotEmpty;
    final favoritePickups = ref.watch(favoritePickupsProvider);

    return AppScaffold(
      title: 'RutasChosica',
      showAppBar: false,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: _PassengerBottomNav(
        currentIndex: index,
        onTap: (value) => context.go(_routeFromIndex(value)),
      ),
      body: IndexedStack(
        index: index,
        children: [
          _PassengerHomeTab(
            name: name,
            hasActiveReservation: hasActiveReservation,
            favoritePickups: favoritePickups,
            onSelectRoute: (direction) {
              context.push(
                '${AppRoutes.passengerSearch}?direction=$direction',
              );
            },
            onSelectFavoritePickup: (value) {
              ref.read(reservaProvider.notifier).setPickup(value);
              AppSnackbars.success(context, 'Punto de recojo seleccionado');
            },
            onAddFavoritePickup: () async {
              final controller = TextEditingController();
              final result = await showDialog<String>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Agregar punto favorito'),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Punto de recojo',
                        hintText: 'Ej: Cruce con Av. Javier Prado...',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(controller.text),
                        child: const Text('Guardar'),
                      ),
                    ],
                  );
                },
              );
              final value = result?.trim();
              if (value == null || value.length < 3) return;
              await ref.read(favoritePickupsProvider.notifier).add(value);
              if (!context.mounted) return;
              AppSnackbars.success(context, 'Punto favorito guardado');
            },
            onOpenNews: () => context.go(AppRoutes.passengerNews),
            onOpenReservationDetail: () => context.go(AppRoutes.passengerReservaActiva),
          ),
          const HistorialScreen(),
          const NoticiasScreen(),
          const PerfilScreen(),
        ],
      ),
    );
  }
}

class _PassengerBottomNav extends StatelessWidget {
  const _PassengerBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.bottomNavShadowBlur,
            offset: const Offset(0, AppSpacing.bottomNavShadowOffsetY),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Mis Viajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_rounded),
            label: 'Noticias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _PassengerHomeTab extends StatelessWidget {
  const _PassengerHomeTab({
    required this.name,
    required this.hasActiveReservation,
    required this.favoritePickups,
    required this.onSelectRoute,
    required this.onSelectFavoritePickup,
    required this.onAddFavoritePickup,
    required this.onOpenNews,
    required this.onOpenReservationDetail,
  });

  final String name;
  final bool hasActiveReservation;
  final List<String> favoritePickups;
  final ValueChanged<String> onSelectRoute;
  final ValueChanged<String> onSelectFavoritePickup;
  final VoidCallback onAddFavoritePickup;
  final VoidCallback onOpenNews;
  final VoidCallback onOpenReservationDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          height: AppSpacing.passengerHomeHeaderHeight,
          width: double.infinity,
          color: AppColors.primaryBlue,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.p20,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Hola, $name',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '¿A dónde vas hoy?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              Text(
                'Selecciona tu ruta',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _RouteCard(
                title: 'San Isidro → Chosica',
                subtitle: 'Vía La Priale o Javier Prado',
                icon: Icons.route_rounded,
                onTap: () => onSelectRoute('si_cho'),
              ),
              const SizedBox(height: AppSpacing.md),
              _RouteCard(
                title: 'Chosica → San Isidro',
                subtitle: 'Múltiples rutas disponibles',
                icon: Icons.route_rounded,
                onTap: () => onSelectRoute('cho_si'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Destinos favoritos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onAddFavoritePickup,
                    child: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (favoritePickups.isEmpty)
                Text(
                  'Aún no tienes puntos guardados.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                )
              else
                ...favoritePickups.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      onTap: () => onSelectFavoritePickup(p),
                      child: AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(Icons.place_rounded, color: AppColors.primaryBlue),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  p,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasActiveReservation) ...[
                const SizedBox(height: AppSpacing.lg),
                _ActiveReservationCard(onViewDetails: onOpenReservationDetail),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Últimas noticias',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenNews,
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...MockData.latestNews.take(2).map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _NewsCard(
                        title: n.title,
                        subtitle: n.subtitle,
                        onTap: onOpenNews,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
      child: SizedBox(
        height: AppSpacing.passengerRouteCardHeight,
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveReservationCard extends StatelessWidget {
  const _ActiveReservationCard({required this.onViewDetails});

  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.primaryBlue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tienes un viaje en curso',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const AppStatusChip(type: AppStatusChipType.onRoute, label: 'En curso'),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Conductor: Conductor Demo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: 'Ver detalles',
              onPressed: onViewDetails,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.newspaper_rounded, color: AppColors.primaryBlue),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
