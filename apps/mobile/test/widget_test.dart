import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/main.dart';

void main() {
  testWidgets('renders the login and handover feature scaffold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SerceSyncMobileApp());

    expect(find.text('SerceSync Mobile'), findsOneWidget);
    expect(find.text('Login to start shift'), findsOneWidget);
    expect(find.text('Seeded demo credentials'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
