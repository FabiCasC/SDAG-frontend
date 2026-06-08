import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../shared/widgets/reusable_ui_components.dart';
import '../../shared/design/app_spacing.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({required this.initialRoute, super.key});

  final String initialRoute;

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _indexFromRoute(widget.initialRoute);
  }

  int _indexFromRoute(String route) {
    switch (route) {
      case AppRoutes.adminFleet:
        return 1;
      case AppRoutes.adminSettings:
        return 2;
      case AppRoutes.adminHome:
      default:
        return 0;
    }
  }

  String _routeFromIndex(int index) {
    switch (index) {
      case 1:
        return AppRoutes.adminFleet;
      case 2:
        return AppRoutes.adminSettings;
      case 0:
      default:
        return AppRoutes.adminHome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RutasChosica · Admin'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: IndexedStack(
            index: _index,
            children: const [
              PlaceholderPage(
                title: 'Admin · Inicio',
                subtitle: 'Módulo Admin listo para implementar.',
              ),
              PlaceholderPage(
                title: 'Admin · Flota',
                subtitle: 'Módulo Admin listo para implementar.',
              ),
              PlaceholderPage(
                title: 'Admin · Configuración',
                subtitle: 'Módulo Admin listo para implementar.',
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
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Flota',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
