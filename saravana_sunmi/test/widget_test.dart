import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:saravana_sunmi/main.dart';
import 'package:saravana_sunmi/providers/scan_print_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ScanPrintProvider(),
        child: const SaravanaApp(),
      ),
    );

    // Verify header title exists
    expect(find.text('SARAVANA STORE'), findsOneWidget);
  });
}
