// Smoke test — verifies the app boots and the home page renders.

import 'package:flutter_test/flutter_test.dart';

import 'package:poliglots_app/main.dart';

void main() {
  testWidgets('Home page renders the brand wordmark', (WidgetTester tester) async {
    await tester.pumpWidget(const PolyglotsApp());
    await tester.pump();

    expect(find.text('POLYGLOTS'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    expect(find.text('Practice Now'), findsOneWidget);
  });
}
