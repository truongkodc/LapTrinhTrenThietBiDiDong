import 'package:flutter_test/flutter_test.dart';
import 'package:fitplan_hutech/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FitPlanApp());
    expect(find.byType(FitPlanApp), findsOneWidget);
  });
}
