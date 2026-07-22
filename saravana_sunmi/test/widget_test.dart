import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saravana_sunmi/main.dart';
import 'package:saravana_sunmi/providers/scan_print_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'is_configured': false});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ScanPrintProvider(),
        child: const SaravanaApp(),
      ),
    );

    // Let the FutureBuilder finish loading
    await tester.pump();
    // Allow printer detection timeout (3 seconds) to complete and rebuild
    await tester.pump(const Duration(seconds: 3));



    // Verify config screen title exists
    expect(find.text('APP CONFIGURATION'), findsOneWidget);
  });
}
