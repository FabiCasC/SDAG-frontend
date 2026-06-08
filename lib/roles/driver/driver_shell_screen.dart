import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../shared/widgets/reusable_ui_components.dart';
import '../../shared/design/app_spacing.dart';

class DriverShellScreen extends StatefulWidget {
  const DriverShellScreen({required this.initialRoute, super.key});

  final String initialRoute;

  @override
  State<DriverShellScreen> createState() => _DriverShellScreenState();
}

class _DriverShellScreenState extends State<DriverShellScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _indexFromRoute(widget.initialRoute);
  }

  int _indexFromRoute(String route) {
    switch (route) {
      case AppRoutes.driverHistorial:
        return 1;
      case AppRoutes.driverNoticias:
        return 2;
      case AppRoutes.driverProfile:
        return 3;
      case AppRoutes.driverHome:
      default:
        return 0;
    }
  }

  String _routeFromIndex(int index) {
    switch (index) {
      case 1:
        return AppRoutes.driverHistorial;
      case 2:
        return AppRoutes.driverNoticias;
      case 3:
        return AppRoutes.driverProfile;
      case 0:
      default:
        return AppRoutes.driverHome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RutasChosica · Conductor'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: IndexedStack(
            index: _index,
            children: const [
              PlaceholderPage(
                title: 'Conductor · Inicio',
                subtitle: 'Módulo Conductor listo para implementar.',
              ),
              PlaceholderPage(
                title: 'Conductor · Viajes',
                subtitle: 'Módulo Conductor listo para implementar.',
              ),
              PlaceholderPage(
                title: 'Conductor · Notificaciones',
                subtitle: 'Módulo Conductor listo para implementar.',
              ),
              PlaceholderPage(
                title: 'Conductor · Perfil',
                subtitle: 'Módulo Conductor listo para implementar.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          context.go(_routeFromIndex(value));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Viajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
