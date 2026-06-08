import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/sdag_app.dart';
import 'app/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    var didNavigateToReset = false;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery && !didNavigateToReset) {
        didNavigateToReset = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          rootNavigatorKey.currentContext?.go('/reset-password');
        });
      }
      if (data.event == AuthChangeEvent.signedOut) {
        didNavigateToReset = false;
      }
    });
  }

  runApp(
    const ProviderScope(
      child: SDAGApp(),
    ),
  );
}
