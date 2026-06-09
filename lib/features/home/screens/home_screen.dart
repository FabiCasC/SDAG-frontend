import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../app/router/app_routes.dart';
import '../../../features/viaje/screens/historial_screen.dart';
import '../../../features/noticias/screens/noticias_screen.dart';
import '../../../features/perfil/screens/perfil_screen.dart';
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
            : 'Pasajero';
    final reserva = ref.watch(reservaProvider);
    final hasActiveReservation = reserva.conductorSeleccionado != null &&
        reserva.reservaId != null &&
        reserva.asientosSeleccionados.isNotEmpty;

    Widget currentTab() {
      switch (index) {
        case 1:
          return const HistorialScreen();
        case 2:
          return const NoticiasScreen();
        case 3:
          return const PerfilScreen();
        case 0:
        default:
          final homeAsync = ref.watch(passengerHomeDataProvider);
          return homeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ScreenMessage(
              title: 'No se pudo cargar el inicio',
              message: error.toString(),
            ),
            data: (homeData) => _PassengerHomeTab(
              name: name,
              hasActiveReservation: hasActiveReservation,
              routes: homeData.routes,
              preferredPickup: homeData.preferredPickup,
              latestNews: homeData.latestNews,
              onSelectRoute: (direction) {
                context.push(
                  '${AppRoutes.passengerSearch}?direction=$direction',
                );
              },
              onSelectFavoritePickup: (value) {
                ref.read(reservaProvider.notifier).setPickup(value);
                AppSnackbars.success(context, 'Punto de recojo seleccionado');
              },
              onOpenNews: () => context.go(AppRoutes.passengerNews),
              onOpenReservationDetail: () => context.go(AppRoutes.passengerReservaActiva),
            ),
          );
      }
    }

    return AppScaffold(
      title: 'RutasChosica',
      showAppBar: false,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: _PassengerBottomNav(
        currentIndex: index,
        onTap: (value) => context.go(_routeFromIndex(value)),
      ),
      body: currentTab(),
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
    required this.routes,
    required this.preferredPickup,
    required this.latestNews,
    required this.onSelectRoute,
    required this.onSelectFavoritePickup,
    required this.onOpenNews,
    required this.onOpenReservationDetail,
  });

  final String name;
  final bool hasActiveReservation;
  final List<_HomeRouteItem> routes;
  final String? preferredPickup;
  final List<_HomeNewsItem> latestNews;
  final ValueChanged<String> onSelectRoute;
  final ValueChanged<String> onSelectFavoritePickup;
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
              if (routes.isEmpty)
                Text(
                  'No hay rutas disponibles por el momento.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                )
              else
                ...routes.map(
                  (route) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _RouteCard(
                      title: route.title,
                      subtitle: route.subtitle,
                      icon: Icons.route_rounded,
                      onTap: () => onSelectRoute(route.direction),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Destinos favoritos',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (preferredPickup == null || preferredPickup!.trim().isEmpty)
                Text(
                  'No tienes un punto de recojo preferido. Configuralo en tu perfil.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  onTap: () => onSelectFavoritePickup(preferredPickup!.trim()),
                  child: AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.place_rounded, color: AppColors.primaryBlue),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              preferredPickup!.trim(),
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
              if (latestNews.isEmpty)
                Text(
                  'No hay noticias publicadas todavía.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                )
              else
                ...latestNews.map(
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

final passengerHomeDataProvider = FutureProvider.autoDispose<_PassengerHomeData>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  final routesResponse = await client
      .from('routes')
      .select('id, name, from_label, to_label')
      .eq('active', true)
      .order('created_at', ascending: false);

  final newsResponse = await client
      .from('news_posts')
      .select('id, title, body, text, created_at')
      .order('created_at', ascending: false)
      .limit(3);

  String? preferredPickup;
  if (userId != null) {
    final profileResponse = await client
        .from('profiles')
        .select('preferred_pickup')
        .eq('id', userId)
        .single();
    preferredPickup = profileResponse['preferred_pickup']?.toString();
  }

  final routes = (routesResponse as List)
      .cast<Map<String, dynamic>>()
      .map(_HomeRouteItem.fromMap)
      .toList();
  final latestNews = (newsResponse as List)
      .cast<Map<String, dynamic>>()
      .map(_HomeNewsItem.fromMap)
      .toList();

  return _PassengerHomeData(
    routes: routes,
    preferredPickup: preferredPickup,
    latestNews: latestNews,
  );
});

class _PassengerHomeData {
  const _PassengerHomeData({
    required this.routes,
    required this.preferredPickup,
    required this.latestNews,
  });

  final List<_HomeRouteItem> routes;
  final String? preferredPickup;
  final List<_HomeNewsItem> latestNews;
}

class _HomeRouteItem {
  const _HomeRouteItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.direction,
  });

  final String id;
  final String title;
  final String subtitle;
  final String direction;

  factory _HomeRouteItem.fromMap(Map<String, dynamic> map) {
    final fromLabel = map['from_label']?.toString().trim() ?? '';
    final toLabel = map['to_label']?.toString().trim() ?? '';
    final name = map['name']?.toString().trim() ?? '';

    return _HomeRouteItem(
      id: map['id'].toString(),
      title: '$fromLabel → $toLabel',
      subtitle: name.isNotEmpty ? name : 'Ruta disponible',
      direction: fromLabel.toLowerCase() == 'san isidro' ? 'si_cho' : 'cho_si',
    );
  }
}

class _HomeNewsItem {
  const _HomeNewsItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;

  factory _HomeNewsItem.fromMap(Map<String, dynamic> map) {
    final body = (map['text'] ?? map['body'] ?? '').toString().trim();
    return _HomeNewsItem(
      id: map['id'].toString(),
      title: map['title']?.toString().trim() ?? 'Sin titulo',
      subtitle: body.isEmpty ? 'Sin descripcion' : body,
    );
  }
}

class _ScreenMessage extends StatelessWidget {
  const _ScreenMessage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
