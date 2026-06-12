import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void popOrGo(BuildContext context, String fallbackRoute) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackRoute);
  }
}

class AppBarLeadingBack extends StatelessWidget {
  const AppBarLeadingBack({required this.fallbackRoute, super.key});

  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => popOrGo(context, fallbackRoute),
    );
  }
}
