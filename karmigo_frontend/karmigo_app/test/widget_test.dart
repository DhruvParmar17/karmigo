import 'package:flutter_test/flutter_test.dart';
import 'package:karmigo_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const KarmigoApp(initialRoute: Scaffold()));
    expect(find.byType(KarmigoApp), findsOneWidget);
  });
}
