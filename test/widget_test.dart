import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sdag/app/sdag_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Supabase.initialize(
      url: 'http://localhost',
      anonKey: 'test',
    );
  });

  testWidgets('SDAGApp renderiza', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SDAGApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SDAGApp), findsOneWidget);
  });
}
