import 'package:flutter_test/flutter_test.dart';
import 'package:shmalik_driver/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ShMalikApp());
    expect(find.byType(ShMalikApp), findsOneWidget);
    // Let the splash screen's delayed auth check finish so no timer is left pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
