import 'package:flutter_test/flutter_test.dart';

import 'package:farmos_flutter/main.dart';

void main() {
  testWidgets('FarmOS app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FarmOSApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Farms'), findsOneWidget);
    expect(find.text('Leaf AI'), findsOneWidget);
  });
}
