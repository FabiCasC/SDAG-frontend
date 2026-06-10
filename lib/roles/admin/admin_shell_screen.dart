import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../shared/design/app_colors.dart';
import '../../shared/design/app_spacing.dart';

class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({
    required this.currentRoute,
    required this.title,
    required this.body,
    super.key,
    this.actions = const [],
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.appBarBottom,
    this.floatingActionButton,
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Color backgroundColor;
  final PreferredSizeWidget? appBarBottom;
  final Widget? floatingActionButton;

  int _indexFromRoute(String route) {
    if (route.startsWith(AppRoutes.adminConductores)) return 1;
    if (route.startsWith(AppRoutes.adminVehiculos)) return 2;
    if (route.startsWith(AppRoutes.adminPagos)) return 3;
    if (route.startsWith(AppRoutes.adminMonitoreo)) return 4;
    if (route.startsWith(AppRoutes.adminAnalitica)) return 5;
    return 0;
  }

  String _routeFromIndex(int index) {
    switch (index) {
      case 1:
        return AppRoutes.adminConductores;
      case 2:
        return AppRoutes.adminVehiculos;
      case 3:
        return AppRoutes.adminPagos;
      case 4:
        return AppRoutes.adminMonitoreo;
      case 5:
        return AppRoutes.adminAnalitica;
      case 0:
      default:
        return AppRoutes.adminHome;
    }
  }

  void _goToIndex(BuildContext context, int index) {
    final nextRoute = _routeFromIndex(index);
    if (currentRoute == nextRoute) return;
    context.go(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _indexFromRoute(currentRoute);
    final useRail = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        title: Text(title),
        actions: actions,
        bottom: appBarBottom,
      ),
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) => _goToIndex(context, value),
                  backgroundColor: const Color(0xFF0F172A),
                  indicatorColor: const Color(0xFFF97316),
                  selectedIconTheme: const IconThemeData(color: Color(0xFF0F172A)),
                  unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Inicio'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.directions_bus_outlined),
                      selectedIcon: Icon(Icons.directions_bus_rounded),
                      label: Text('Conductores'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_shipping_outlined),
                      selectedIcon: Icon(Icons.local_shipping_rounded),
                      label: Text('Vehículos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.attach_money_outlined),
                      selectedIcon: Icon(Icons.attach_money_rounded),
                      label: Text('Pagos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded),
                      label: Text('Monitoreo'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart_rounded),
                      label: Text('Analítica'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.p20,
                      right: AppSpacing.p20,
                      top: AppSpacing.p20,
                    ),
                    child: body,
                  ),
                ),
              ],
            )
          : body,
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) => _goToIndex(context, value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions_bus_outlined),
                  selectedIcon: Icon(Icons.directions_bus_rounded),
                  label: 'Conductores',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping_rounded),
                  label: 'Vehículos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.attach_money_outlined),
                  selectedIcon: Icon(Icons.attach_money_rounded),
                  label: 'Pagos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: 'Monitoreo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Analítica',
                ),
              ],
            ),
      floatingActionButton: floatingActionButton,
    );
  }
}
