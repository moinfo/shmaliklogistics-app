import 'package:flutter_test/flutter_test.dart';
import 'package:transmas_logistics/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const TransMasApp());
    expect(find.byType(TransMasApp), findsOneWidget);

    // Let the splash screen's delayed auth check finish so no timer is left pending.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
