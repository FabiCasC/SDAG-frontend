import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pzmepsygptbgakmzhrkd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6bWVwc3lncHRiZ2FrbXpocmtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NTQ0ODcsImV4cCI6MjA5NTMzMDQ4N30.Qk7Is0qBLmVLAXN_akaBQBDcijESYpTx1qtZUqdVCUA',
  );

  runApp(const SDAGApp());
}

class SDAGApp extends StatelessWidget {
  const SDAGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: AppTheme.languageCode,
          builder: (context, lang, __) {
            return MaterialApp(
              title: 'SDAG',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              locale: Locale(lang),
              home: const LoginScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}