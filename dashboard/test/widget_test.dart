import 'package:dashboard/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard renders the Overview page', (tester) async {
    await tester.pumpWidget(const DashboardApp());
    await tester.pump();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Riverside Academy'.toUpperCase()), findsOneWidget);
  });
}
