import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HanziApp());
    await tester.pump();
    expect(find.byType(HanziApp), findsOneWidget);
  });
}
