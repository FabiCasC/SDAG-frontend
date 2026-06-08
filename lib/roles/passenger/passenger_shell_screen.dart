import 'package:flutter/material.dart';

import '../../features/home/screens/home_screen.dart';

class PassengerShellScreen extends StatelessWidget {
  const PassengerShellScreen({required this.initialRoute, super.key});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return HomeScreen(initialRoute: initialRoute);
  }
}
