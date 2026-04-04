import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_web/main.dart';

void main() {
  testWidgets('renders the web foundation placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SerceSyncWebApp());

    expect(find.text('SerceSync Web'), findsWidgets);
    expect(
      find.text('Foundation scaffold for the manager web app.'),
      findsOneWidget,
    );
  });
}
