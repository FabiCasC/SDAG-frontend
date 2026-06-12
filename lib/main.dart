import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_routes.dart';
import 'app/sdag_app.dart';
import 'app/router/app_router.dart';

void _navigateToResetPassword({int attempt = 0}) {
  if (attempt > 60) {
    debugPrint('[Auth] no se pudo navegar a reset-password: contexto no disponible');
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      debugPrint('[Auth] passwordRecovery detectado → navegando a reset-password');
      GoRouter.of(context).go(AppRoutes.resetPassword);
      return;
    }

    debugPrint('[Auth] contexto aún no listo (intento ${attempt + 1}), reintentando...');
    _navigateToResetPassword(attempt: attempt + 1);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'env.json');
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url != null && url.isNotEmpty && anonKey != null && anonKey.isNotEmpty) {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('[Auth] event: ${data.event}');
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _navigateToResetPassword();
      }
    });
  }

  runApp(
    const ProviderScope(
      child: SDAGApp(),
    ),
  );
}
