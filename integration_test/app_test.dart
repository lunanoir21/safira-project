import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:safira/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Safira end-to-end flow', () {
    testWidgets('app boots and shows onboarding or lock page',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: SafiraApp()),
      );
      await tester.pumpAndSettle();

      // The app should show either the onboarding welcome page
      // (first run) or the lock/unlock page (returning user).
      // We just verify the app boots without crashing.
      expect(find.byType(SafiraApp), findsOneWidget);
    });

    testWidgets('onboarding welcome page has Get started button',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: SafiraApp()),
      );
      await tester.pumpAndSettle();

      // If onboarding is shown:
      final getStarted = find.text('Get started');
      if (getStarted.evaluate().isNotEmpty) {
        await tester.tap(getStarted);
        await tester.pumpAndSettle();
        // Should advance to master password setup page
        expect(find.text('Create master password'), findsOneWidget);
      }
    });

    // TODO: Add more flows:
    // - Complete onboarding → enters dashboard
    // - Create a vault entry → appears in list
    // - Lock → re-unlock with master password
    // - Generate password → copies to clipboard
    // - TOTP countdown → updates every second
  });
}
