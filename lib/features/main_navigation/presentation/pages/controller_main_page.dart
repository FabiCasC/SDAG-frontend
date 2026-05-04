import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dispatch/presentation/pages/dispatch_view.dart';
import '../../../history/presentation/pages/history_view.dart';
import '../../../dashboard/presentation/pages/ranking_view.dart';

class ControllerMainPage extends StatefulWidget {
  const ControllerMainPage({super.key});

  @override
  State<ControllerMainPage> createState() => _ControllerMainPageState();
}

class _ControllerMainPageState extends State<ControllerMainPage> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    DispatchView(),
    HistoryView(),
    RankingView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.power_settings_new_outlined),
              activeIcon: Icon(Icons.power_settings_new),
              label: 'Despacho',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Ranking',
            ),
          ],
        ),
      ),
    );
  }
}
