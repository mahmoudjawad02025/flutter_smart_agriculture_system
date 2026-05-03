import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_smart_agriculture_system/main.dart';

void main() {
  testWidgets('Disease detection page renders', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text('Cucumber Leaf Analysis'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.text('Connect API'), findsOneWidget);
  });
}
