import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/main.dart';

void main() {
  testWidgets('renders the mobile foundation placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SerceSyncMobileApp());

    expect(find.text('SerceSync Mobile'), findsWidgets);
    expect(
      find.text('Foundation scaffold for the care staff app.'),
      findsOneWidget,
    );
  });
}
