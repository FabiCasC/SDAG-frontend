import 'package:flutter/widgets.dart';

import 'app_session.dart';

class AppStateScope extends InheritedNotifier<AppSession> {
  const AppStateScope({
    required AppSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}

